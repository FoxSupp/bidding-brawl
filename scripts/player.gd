class_name Player
extends CharacterBody2D

signal died(player_id: int)

@onready var input_synch: Node2D = $InputSynch
@onready var muzzle_rotation: Node2D = $MuzzleRotation
@onready var hp_bar: ProgressBar = $HP/HPBar


const SPEED = 300.0
const JUMP_VELOCITY = -400.0

var spectating_cam

@export var health: int = 5
@export var score: int = 0
@export var dead := false

func _enter_tree() -> void:
	get_node("InputSynch").set_multiplayer_authority(name.to_int())

func _ready() -> void:
	spectating_cam = get_tree().root.get_node("/root/Game/Camera2D")
	hp_bar.max_value = health
	hp_bar.value = health
	if input_synch.is_multiplayer_authority():
		get_node("ColorRect").color = Color.YELLOW

func _physics_process(delta: float) -> void:
	if input_synch.is_multiplayer_authority():
		get_node("Camera2D").enabled = !dead
		spectating_cam.enabled = dead
	# Simulate only on the authoritative peer (server).
	if not is_multiplayer_authority():
		return
	if not dead:
		_handle_movement(delta)
		_handle_aiming()
		_handle_shooting()
		_check_health()

func _handle_movement(delta: float):
	# Apply gravity, then handle input from InputSynch, then move.
	if not is_on_floor():
		velocity += get_gravity() * delta
	# Handle jump.
	if input_synch.jump_input and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction: float = input_synch.move_input
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	move_and_slide()

func _handle_aiming():
	var aim_direction = input_synch.mouse_pos - position
	muzzle_rotation.rotation = aim_direction.angle()

func _handle_shooting():
	if input_synch.fire_input:
		var projectile = preload("res://scenes/bullet.tscn").instantiate()
		projectile.global_position = muzzle_rotation.get_node("Muzzle").global_position
		projectile.rotation = muzzle_rotation.rotation
		projectile.dir = muzzle_rotation.get_node("Muzzle").global_position.direction_to(input_synch.mouse_pos)
		get_tree().root.get_node("Game/Projectiles").add_child(projectile, true)
		projectile.player_id = name.to_int()

func take_damage(damage: int, shooter_id: int) -> void:
	# Server-authoritative: only server mutates health
	if not is_multiplayer_authority():
		return
	health -= damage
	hp_bar.value = health
	if health <= 0:
		if shooter_id != name.to_int():
			get_tree().get_root().get_node("Game").add_score(1, shooter_id)

func add_score(score_to_add: int) -> void:
	# Server-authoritative: only server mutates score
	if not is_multiplayer_authority():
		return
	self.score += score_to_add

func _check_health() -> void:
	if health <= 0:
		dead = true
		visible = false
		get_node("CollisionShape2D").disabled = true
		emit_signal("died", name.to_int())
