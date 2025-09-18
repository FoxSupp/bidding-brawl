extends Node2D

@export var move_input: float = 0.0
@export var jump_input: bool = false
@export var mouse_pos: Vector2
@export var fire_input: bool = false
@export var scoreboard_show: bool = false

func _ready() -> void:
	var is_owner: bool = get_multiplayer_authority() == multiplayer.get_unique_id()
	set_process(is_owner)
	set_physics_process(is_owner)

func _physics_process(_delta: float) -> void:
	# Sample on physics frames and use pressed state to avoid one-frame misses over network
	move_input = Input.get_axis("move_left", "move_right")
	jump_input = Input.is_action_just_pressed("jump")
	mouse_pos = get_global_mouse_position()
	fire_input = Input.is_action_pressed("fire")
	scoreboard_show = Input.is_action_pressed("scoreboard")
	
