class_name Player
extends CharacterBody2D

signal died(player_id: int)

@onready var input_synch: Node2D = $InputSynch
@onready var muzzle_rotation: Node2D = $MuzzleRotation
@onready var hp_bar: ProgressBar = $HP/HPBar
@onready var camera: Camera2D = $Camera2D
@onready var color_rect: ColorRect = $ColorRect
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var projectiles_root: Node = get_tree().root.get_node("/root/Game/Projectiles")

const SPEED: float = 300.0
const JUMP_VELOCITY: float = -400.0
const KILL_MONEY: int = 100
const BULLET_SCENE = preload("res://scenes/bullet.tscn")

var spectating_cam: Camera2D

var shot_cooldown_reset: float = 1.0
var shoot_cooldown: float = 0.0

@export var health: int = 5
@export var score: int = 0
@export var dead: bool = false

func _enter_tree() -> void:
	get_node("InputSynch").set_multiplayer_authority(name.to_int())

func _ready() -> void:
	spectating_cam = get_tree().root.get_node("/root/Game/Camera2D")
	hp_bar.max_value = health
	hp_bar.value = health
	
	if input_synch.is_multiplayer_authority():
		color_rect.color = Color.YELLOW

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
	
	if health <= 0:
		_handle_death()

func _handle_movement(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if input_synch.jump_input and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	velocity.x = input_synch.move_input * SPEED if input_synch.move_input else move_toward(velocity.x, 0, SPEED)
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
	shoot_cooldown = shot_cooldown_reset
	var muzzle: Marker2D = muzzle_rotation.get_node("Muzzle")
	var dir := muzzle.global_position.direction_to(input_synch.mouse_pos).normalized()
	var ctx := {
		"muzzle_pos": muzzle.global_position,
		"dir": dir,
		"projectile_count": 1,
		"damage": 1,
		"speed": 900.0,
		"lifetime": 2,
		"owner_peer_id": name.to_int()
	}
	
	var projectile: Node = BULLET_SCENE.instantiate()
	projectile.global_position = ctx.muzzle_pos
	projectile.rotation = ctx.dir.angle()
	projectile.dir = ctx.dir
	projectile.owner_peer_id = name.to_int()
	
	if "damage" in projectile: projectile.damage = ctx.damage
	if "speed" in projectile: projectile.speed = ctx.speed
	if "lifetime" in projectile: projectile.lifetime = ctx.lifetime
	projectiles_root.add_child(projectile, true)
	
func _handle_death() -> void:
	dead = true
	visible = false
	collision.disabled = true
	
	if input_synch.is_multiplayer_authority():
		input_synch.set_multiplayer_authority(1)
	
	died.emit(name.to_int())

func take_damage(damage: int, shooter_id: int) -> void:
	if not is_multiplayer_authority():
		return
	
	health -= damage
	hp_bar.value = health
	
	if health <= 0 and shooter_id != name.to_int():
		SessionManager.rpc("addMoney", shooter_id, KILL_MONEY)

func despawn_player() -> void:
	dead = true
	if not is_multiplayer_authority():
		return
	# Safe node access to prevent null reference errors
	var input_synch_node = input_synch.get_node_or_null("InputSynch")
	if input_synch_node and is_instance_valid(input_synch_node):
		input_synch_node.public_visibility = false
	await get_tree().process_frame
	queue_free()
