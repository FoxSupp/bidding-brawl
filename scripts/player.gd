## Player Controller
## Handles player movement, combat, animations, and multiplayer synchronization
class_name Player
extends CharacterBody2D

# Signals
signal died(player_id: int)

# Node references
@onready var shoot_sound: AudioStreamPlayer2D = $ShootSound
@onready var jump_sound: AudioStreamPlayer2D = $JumpSound
@onready var hit_sound: AudioStreamPlayer2D = $HitSound
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var input_synch: Node2D = $InputSynch
@onready var muzzle_rotation: Node2D = $MuzzleRotation
@onready var label_hp: Label = $HP/LabelHP
@onready var hp_bar: ProgressBar = $HP/HPBar
@onready var camera: Camera2D = $Camera2D
@onready var label_playername: Label = $LabelPlayername
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var projectiles_root: Node = get_tree().root.get_node("/root/Game/Projectiles")

# Constants
const BULLET_SCENE = preload("res://scenes/bullet.tscn")

# Camera references
var spectating_cam: Camera2D

# Combat variables
var shoot_cooldown: float = 0.0

# Upgrade variables
var upgrade_speed_bonus: float = 0.0
var upgrade_multishot_count: int = 0
var upgrade_firerate_multiplier: float = 1.0
var upgrade_max_health: int = 0
var upgrade_jump_height: float = 0.0
var upgrade_multijump_count: int = 0
var upgrade_bounce_count: int = 0
var upgrade_homing_time: float = 0.0
var upgrades: Array[UpgradeBase] = []

# Player stats
@export var current_health: int = 100
@export var max_health: int = 100
@export var score: int = 0
@export var dead: bool = false

# Animation state tracking
var is_jumping: bool = false
var is_falling: bool = false

# Jump tracking for multijump
var remaining_jumps: int = 0

func _enter_tree() -> void:
	get_node("InputSynch").set_multiplayer_authority(name.to_int())

func _ready() -> void:
	# Server-side initialization
	if multiplayer.is_server():
		_init_upgrades()
		_initialize_health()
		# Initialize jump counter (1 base jump + multijump upgrades)
		remaining_jumps = 1 + upgrade_multijump_count
		label_playername.text = NetworkManager.players[input_synch.get_multiplayer_authority()].username
	
	# Client-side camera setup
	if input_synch.is_multiplayer_authority():
		var arena_node = get_tree().get_first_node_in_group("arena")
		if arena_node and arena_node.has_node("SpectatingCam"):
			spectating_cam = arena_node.get_node("SpectatingCam")
	
	# Connect signals
	sprite.animation_finished.connect(_on_animation_finished)

func _physics_process(delta: float) -> void:
	# Handle camera switching between game and spectating
	if input_synch.is_multiplayer_authority():
		camera.enabled = not dead
		if spectating_cam:
			spectating_cam.enabled = dead
	
	# Only process game logic for the authority player when alive
	if not is_multiplayer_authority() or dead:
		return
	
	# Check for falling out of bounds
	if position.y >= GameConfig.DEATH_Y_THRESHOLD:
		_handle_death()
		return
	
	# Update cooldowns
	if shoot_cooldown > 0:
		shoot_cooldown -= delta
	
	# Handle player actions
	_handle_movement(delta)
	_handle_aiming()
	_handle_shooting()
	
	# Check for death
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
			# Reset jumps when touching ground (1 base jump + multijump upgrades)
			remaining_jumps = 1 + upgrade_multijump_count
	
	# Handle jumping - both ground and air jumps
	if input_synch.jump_input and remaining_jumps > 0:
		is_jumping = true
		is_falling = false
		sprite.play("jump")
		var cur_jump_velocity = GameConfig.PLAYER_JUMP_VELOCITY - upgrade_jump_height
		velocity.y = cur_jump_velocity
		remaining_jumps -= 1
		# Play jump sound via RPC
		rpc("play_jump_sound_rpc")
	
	var current_speed = GameConfig.PLAYER_BASE_SPEED + upgrade_speed_bonus
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
	if not input_synch.fire_input or shoot_cooldown > 0:
		return
	
	# Set cooldown based on firerate upgrade
	shoot_cooldown = GameConfig.SHOT_COOLDOWN_BASE * upgrade_firerate_multiplier
	
	var muzzle: Marker2D = muzzle_rotation.get_node("Muzzle")
	var base_dir := muzzle.global_position.direction_to(input_synch.mouse_pos).normalized()
	
	# Fire main bullet
	_shoot_bullet(muzzle.global_position, base_dir)
	
	# Fire additional bullets for multishot
	for i in range(upgrade_multishot_count):
		var angle_offset = deg_to_rad(GameConfig.MULTISHOT_ANGLE_OFFSET * (i + 1)) * (1 if i % 2 == 0 else -1)
		var offset_dir = base_dir.rotated(angle_offset)
		_shoot_bullet(muzzle.global_position, offset_dir)

func _shoot_bullet(pos: Vector2, dir: Vector2) -> void:
	var projectile: Node = BULLET_SCENE.instantiate()
	projectile.global_position = pos
	projectile.rotation = dir.angle()
	projectile.dir = dir
	projectile.owner_peer_id = name.to_int()
	
	# Set bullet properties using GameConfig
	if "damage" in projectile: 
		projectile.damage = GameConfig.PLAYER_BASE_DAMAGE
	if "speed" in projectile: 
		projectile.speed = GameConfig.BULLET_SPEED
	if "lifetime" in projectile: 
		projectile.lifetime = GameConfig.BULLET_BASE_LIFETIME
	if "bounce" in projectile: 
		projectile.bounce = upgrade_bounce_count
	if "homing_time" in projectile: 
		projectile.homing_time = upgrade_homing_time
		
	projectiles_root.add_child(projectile, true)
	
	# Play shoot sound via RPC
	rpc("play_shoot_sound_rpc")

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
	
	# Award money and kills when player dies (but not suicide)
	if current_health <= 0 and shooter_id != name.to_int():
		SessionManager.add_money(int(name), GameConfig.DEATH_MONEY_REWARD)
		SessionManager.add_money(shooter_id, GameConfig.KILL_MONEY_REWARD)
		SessionManager.add_kill(shooter_id)

func play_hit_sound() -> void:
	# Play hit sound via RPC - only shooter hears it
	rpc("play_hit_sound_rpc")
		
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

func _initialize_health() -> void:
	# Calculate total max health including upgrades
	max_health = GameConfig.PLAYER_BASE_HEALTH + upgrade_max_health
	current_health = max_health
	
	# Update UI elements
	hp_bar.max_value = max_health
	hp_bar.value = max_health
	label_hp.text = str(current_health) + "/" + str(max_health)

# RPC functions for sound synchronization
@rpc("any_peer", "call_local")
func play_jump_sound_rpc() -> void:
	# Jump sound only for the jumper
	if input_synch.is_multiplayer_authority():
		jump_sound.play()

@rpc("any_peer", "call_local") 
func play_shoot_sound_rpc() -> void:
	# Shoot sound for everyone, but louder for shooter
	if input_synch.is_multiplayer_authority():
		# Louder for the shooter
		shoot_sound.volume_db = GameConfig.SHOOTER_VOLUME_DB
		shoot_sound.pitch_scale = 1.0
	else:
		# Quieter for other clients
		shoot_sound.volume_db = GameConfig.OTHER_PLAYERS_VOLUME_DB
		shoot_sound.pitch_scale = GameConfig.OTHER_PLAYERS_PITCH_SCALE
	shoot_sound.play()

@rpc("any_peer", "call_local")
func play_hit_sound_rpc() -> void:
	# Hit sound only for the shooter
	if input_synch.is_multiplayer_authority():
		hit_sound.play()
