class_name Player
extends CharacterBody2D

signal died(player_id: int)

@onready var input_synch: Node2D = $InputSynch
@onready var muzzle_rotation: Node2D = $MuzzleRotation
@onready var hp_bar: ProgressBar = $HP/HPBar
@onready var camera: Camera2D = $Camera2D
@onready var color_rect: ColorRect = $ColorRect
@onready var collision: CollisionShape2D = $CollisionShape2D

const SPEED: float = 300.0
const JUMP_VELOCITY: float = -400.0
const BULLET_SCENE = preload("res://scenes/bullet.tscn")

var spectating_cam: Camera2D

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
	
	var projectile: Node = BULLET_SCENE.instantiate()
	var muzzle: Marker2D = muzzle_rotation.get_node("Muzzle")
	
	projectile.global_position = muzzle.global_position
	projectile.rotation = muzzle_rotation.rotation
	projectile.dir = muzzle.global_position.direction_to(input_synch.mouse_pos)
	projectile.player_id = name.to_int()
	
	get_tree().root.get_node("Game/Projectiles").add_child(projectile, true)

func take_damage(damage: int, shooter_id: int) -> void:
	if not is_multiplayer_authority():
		return
	
	health -= damage
	hp_bar.value = health
	
	if health <= 0 and shooter_id != name.to_int():
		get_tree().get_root().get_node("Game").add_score(1, shooter_id)

func add_score(score_to_add: int) -> void:
	if not is_multiplayer_authority():
		return
	score += score_to_add

func _handle_death() -> void:
	dead = true
	visible = false
	collision.disabled = true
	
	if input_synch.is_multiplayer_authority():
		input_synch.set_multiplayer_authority(1)
	
	died.emit(name.to_int())
	
	if is_multiplayer_authority():
		get_tree().create_timer(0.1).timeout.connect(_despawn_player)

func _despawn_player() -> void:
	if not is_multiplayer_authority():
		return
		
	var spawner = get_tree().root.get_node_or_null("Game/PlayerSpawner")
	if spawner and spawner.has_method("despawn"):
		spawner.despawn(self)
	else:
		queue_free()
