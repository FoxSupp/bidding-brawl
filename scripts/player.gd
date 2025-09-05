class_name Player
extends CharacterBody2D

signal died(player_id: int)

@onready var input_synch: Node2D = $InputSynch
@onready var muzzle_rotation: Node2D = $MuzzleRotation
@onready var hp_bar: ProgressBar = $HP/HPBar


const SPEED: float = 300.0
const JUMP_VELOCITY: float = -400.0

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
        get_node("ColorRect").color = Color.YELLOW

func _physics_process(delta: float) -> void:
    if input_synch.is_multiplayer_authority():
        get_node("Camera2D").enabled = !dead
        spectating_cam.enabled = dead
    if not is_multiplayer_authority():
        return
    if not dead:
        _handle_movement(delta)
        _handle_aiming()
        _handle_shooting()
        _check_health()

func _handle_movement(delta: float) -> void:
    if not is_on_floor():
        velocity += get_gravity() * delta
    if input_synch.jump_input and is_on_floor():
        velocity.y = JUMP_VELOCITY
    var direction: float = input_synch.move_input
    if direction:
        velocity.x = direction * SPEED
    else:
        velocity.x = move_toward(velocity.x, 0, SPEED)
    move_and_slide()

func _handle_aiming() -> void:
    var aim_direction: Vector2 = input_synch.mouse_pos - position
    muzzle_rotation.rotation = aim_direction.angle()

func _handle_shooting() -> void:
    if input_synch.fire_input:
        var projectile: Bullet = preload("res://scenes/bullet.tscn").instantiate()
        projectile.global_position = muzzle_rotation.get_node("Muzzle").global_position
        projectile.rotation = muzzle_rotation.rotation
        projectile.dir = muzzle_rotation.get_node("Muzzle").global_position.direction_to(input_synch.mouse_pos)
        get_tree().root.get_node("Game/Projectiles").add_child(projectile, true)
        projectile.player_id = name.to_int()

func take_damage(damage: int, shooter_id: int) -> void:
    if not is_multiplayer_authority():
        return
    health -= damage
    hp_bar.value = health
    if health <= 0:
        if shooter_id != name.to_int():
            get_tree().get_root().get_node("Game").add_score(1, shooter_id)

func add_score(score_to_add: int) -> void:
    if not is_multiplayer_authority():
        return
    score += score_to_add

func _check_health() -> void:
    if health <= 0:
        dead = true
        visible = false
        get_node("CollisionShape2D").disabled = true
        died.emit(name.to_int())
