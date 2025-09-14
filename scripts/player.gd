class_name Player
extends CharacterBody2D

signal died(player_id: int)

@onready var shoot_sound: AudioStreamPlayer2D = $ShootSound
@onready var jump_sound: AudioStreamPlayer2D = $JumpSound

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var input_synch: Node2D = $InputSynch
@onready var muzzle_rotation: Node2D = $MuzzleRotation
@onready var label_hp: Label = $HP/LabelHP
@onready var hp_bar: ProgressBar = $HP/HPBar
@onready var camera: Camera2D = $Camera2D
@onready var label_playername: Label = $LabelPlayername
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var projectiles_root: Node = get_tree().root.get_node("/root/Game/Projectiles")

const BASE_DAMAGE: float = 10.0
const BASE_SPEED: float = 300.0
const JUMP_VELOCITY: float = -500.0
const KILL_MONEY: int = 100
const DEATH_MONEY: int = 20
const BULLET_SCENE = preload("res://scenes/bullet.tscn")

var spectating_cam: Camera2D

var shot_cooldown_reset: float = 0.5
var shoot_cooldown: float = 0.0

""" Upgrade Variables """
var upgrade_speed_bonus: float = 0.0
var upgrade_multishot_count: int = 0
var upgrade_firerate_multiplier: float = 1.0
var upgrade_max_health: int = 0
var upgrade_jump_height: float = 0.0

var upgrades: Array[UpgradeBase] = []

@export var current_health: int = 100
@export var max_health: int = 100
@export var score: int = 0
@export var dead: bool = false

# Animation state tracking
var is_jumping: bool = false
var is_falling: bool = false

func _enter_tree() -> void:
	get_node("InputSynch").set_multiplayer_authority(name.to_int())

func _ready() -> void:
	
	"""Debug for all things only happening on Server Player"""
	if multiplayer.is_server() and input_synch.get_multiplayer_authority() == 1:
		#UpgradeManager.apply_upgrade(self, "upgrade_multishot")
		pass
	
	if multiplayer.is_server():
		_init_upgrades()
		initialize_health()
		label_playername.text = NetworkManager.players[input_synch.get_multiplayer_authority()].username
	
	
	if input_synch.is_multiplayer_authority():
		spectating_cam = get_tree().root.get_node("/root/Game/Camera2D")
	
	# Connect the animation finished signal
	sprite.animation_finished.connect(_on_animation_finished)

func _physics_process(delta: float) -> void:
	if input_synch.is_multiplayer_authority():
		camera.enabled = not dead
		spectating_cam.enabled = dead
	
	if not is_multiplayer_authority() or dead:
		return
	
	# Cooldown timer runterzählen
	if shoot_cooldown > 0:
		shoot_cooldown -= delta
	
	_handle_movement(delta)
	_handle_aiming()
	_handle_shooting()
	
	if current_health <= 0:
		_handle_death()

func _handle_movement(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
		
		# Only start fall animation if we're not jumping and actually falling
		if velocity.y > 0 and not is_jumping:
			if not is_falling:
				is_falling = true
				sprite.play("fall")
	else:
		# Reset states when touching ground
		if is_jumping or is_falling:
			is_jumping = false
			is_falling = false
	
	if input_synch.jump_input and is_on_floor():
		is_jumping = true
		is_falling = false
		sprite.play("jump")
		var cur_jump_velocity = JUMP_VELOCITY - upgrade_jump_height
		velocity.y = cur_jump_velocity
		if input_synch.is_multiplayer_authority():
			jump_sound.play()
	
	var current_speed = BASE_SPEED + upgrade_speed_bonus
	velocity.x = input_synch.move_input * current_speed if input_synch.move_input else move_toward(velocity.x, 0, current_speed)
	
	# Handle sprite flipping
	if input_synch.move_input < 0:
		sprite.flip_h = true
	elif input_synch.move_input > 0:
		sprite.flip_h = false
	
	# Only play walk/idle animations if not jumping or falling
	if is_on_floor() and not is_jumping:
		if input_synch.move_input != 0:
			sprite.play("walk")
		else:
			sprite.play("idle")
	
	move_and_slide()

func _handle_aiming() -> void:
	muzzle_rotation.rotation = (input_synch.mouse_pos - position).angle()

func _handle_shooting() -> void:
	if not input_synch.fire_input:
		return
	
	# Prüfe ob Cooldown noch aktiv ist
	if shoot_cooldown > 0:
		return
	
	# Setze 1 Sekunde Cooldown
	shoot_cooldown = shot_cooldown_reset * upgrade_firerate_multiplier
	var muzzle: Marker2D = muzzle_rotation.get_node("Muzzle")
	var base_dir := muzzle.global_position.direction_to(input_synch.mouse_pos).normalized()
	
	_shoot_bullet(muzzle.global_position, base_dir)
		# Zusätzliche Projektile für Multishot
	for i in range(upgrade_multishot_count):
		var angle_offset = deg_to_rad(15 * (i + 1)) * (1 if i % 2 == 0 else -1)
		var offset_dir = base_dir.rotated(angle_offset)
		_shoot_bullet(muzzle.global_position, offset_dir)

func _shoot_bullet(pos: Vector2, dir: Vector2):
	var projectile: Node = BULLET_SCENE.instantiate()
	projectile.global_position = pos
	projectile.rotation = dir.angle()
	projectile.dir = dir
	projectile.owner_peer_id = name.to_int()
	
	if "damage" in projectile: projectile.damage = BASE_DAMAGE
	if "speed" in projectile: projectile.speed = 900
	if "lifetime" in projectile: projectile.lifetime = 2
	projectiles_root.add_child(projectile, true)
	if !input_synch.is_multiplayer_authority():
		shoot_sound.volume_db = -16
		shoot_sound.pitch_scale = 0.70
	shoot_sound.play()

func _handle_death() -> void:
	dead = true
	visible = false
	collision.disabled = true
	
	if input_synch.is_multiplayer_authority():
		input_synch.set_multiplayer_authority(1)
	
	died.emit(name.to_int())

func _init_upgrades() -> void:
	for upgrade_id in SessionManager.player_stats[name.to_int()].get("upgrades", []):
		UpgradeManager.apply_upgrade(self, upgrade_id)
	for upgrade in upgrades:
		upgrade.apply(self)

func take_damage(damage: int, shooter_id: int) -> void:
	if not is_multiplayer_authority():
		return
	
	current_health -= damage
	hp_bar.value = current_health
	label_hp.text = str(current_health) + "/" + str(max_health)
	
	# TODO: implement Fix to not award 2 times Money if killed with 2 Bullets due to Multishot
	if current_health <= 0 and shooter_id != name.to_int():
		SessionManager.add_money(int(name), DEATH_MONEY)
		SessionManager.add_money(shooter_id, KILL_MONEY)
		SessionManager.add_kill(shooter_id)

func _on_animation_finished() -> void:
	# When jump animation finishes, check if we're still in the air
	if sprite.animation == "jump":
		is_jumping = false
		if not is_on_floor():
			is_falling = true
			sprite.play("fall")
		else:
			# We landed, play appropriate ground animation
			if input_synch.move_input != 0:
				sprite.play("walk")
			else:
				sprite.play("idle")

func despawn_player() -> void:
	dead = true
	if not is_multiplayer_authority():
		return
	# Safe node access to prevent null reference errors
	if is_instance_valid(input_synch) and input_synch.has_node("InputSynch"):
		var input_synch_node = input_synch.get_node("InputSynch")
		if is_instance_valid(input_synch_node):
			input_synch_node.public_visibility = false
	await get_tree().process_frame
	queue_free()

func initialize_health() -> void:
	# Calculate total max health including upgrades
	max_health = max_health + upgrade_max_health  # Base health (100) + upgrade bonus
	current_health = max_health
	
	# Update UI elements
	hp_bar.max_value = max_health
	hp_bar.value = max_health
	label_hp.text = str(current_health) + "/" + str(max_health)
