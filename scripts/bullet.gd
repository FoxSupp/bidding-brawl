extends RigidBody2D

@export var speed: float = 1000.0
@export var damage: int = 1
@export var dir: Vector2
@export var owner_peer_id: int
@export var lifetime: float
@export var bounce: int = 0
@export var homing_time: float = 0.1



func _ready() -> void:
	linear_velocity = dir * speed

func _process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	
	if homing_time > 0:
		homing_time -= delta
		var target_player = get_target_player()
		if target_player:
			# Direct smooth movement towards target (position-based)
			var move_speed = speed * delta
			global_position = global_position.move_toward(target_player.global_position, move_speed)
			# Set rotation to face the target
			rotation = (target_player.global_position - global_position).angle()
		
		if homing_time <= 0:
			homing_time = 0.0
			# Switch back to velocity-based movement
			var final_direction = (get_target_player().global_position - global_position).normalized() if get_target_player() else dir
			linear_velocity = final_direction * speed

	if linear_velocity.length() > 0:
		rotation = linear_velocity.angle()
	lifetime -= delta
	if lifetime <= 0:
		call_deferred("queue_free")

func get_target_player() -> Player:
	var players = get_tree().get_nodes_in_group("player")
	var nearest_player: Player = null
	var min_dist: float = INF
	for player in players:
		if player.name.to_int() != owner_peer_id:
			var dist = global_position.distance_to(player.global_position)
			if dist < min_dist:
				min_dist = dist
				nearest_player = player
	return nearest_player

func _on_body_entered(body: Node) -> void:
	if not is_multiplayer_authority():
		return
	
	if body is Player:
		body.take_damage(damage, owner_peer_id)
		var shooter_player = get_shooter_player()
		if shooter_player and shooter_player.has_method("play_hit_sound_rpc"):
			shooter_player.rpc("play_hit_sound_rpc")
	if bounce <= 0:
		call_deferred("queue_free")
	bounce -= 1


func get_shooter_player() -> Player:
	var players = get_tree().get_nodes_in_group("player")
	for player in players:
		if player.name.to_int() == owner_peer_id:
			return player
	return null
