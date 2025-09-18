## Bullet/Projectile Controller
## Handles bullet physics, collision, homing, and bouncing mechanics
extends RigidBody2D

# Bullet properties
@export var speed: float = 1000.0
@export var damage: int = 1
@export var dir: Vector2
@export var owner_peer_id: int
@export var lifetime: float
@export var bounce: int = 0
@export var homing_time: float = 0.0



func _ready() -> void:
	linear_velocity = dir * speed

func _process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	
	# Handle homing behavior
	if homing_time > 0:
		homing_time -= delta
		var target_player = _get_target_player()
		if target_player:
			# Direct smooth movement towards target (position-based)
			var move_speed = speed * delta
			global_position = global_position.move_toward(target_player.global_position, move_speed)
			# Set rotation to face the target
			rotation = (target_player.global_position - global_position).angle()
		
		# Switch back to velocity-based movement when homing ends
		if homing_time <= 0:
			homing_time = 0.0
			var final_target = _get_target_player()
			var final_direction = final_target.global_position - global_position if final_target else dir
			linear_velocity = final_direction.normalized() * speed

	# Update rotation to match movement direction
	if linear_velocity.length() > 0:
		rotation = linear_velocity.angle()
		
	# Handle lifetime expiration
	lifetime -= delta
	if lifetime <= 0:
		call_deferred("queue_free")

func _get_target_player() -> Player:
	var players = get_tree().get_nodes_in_group("player")
	var nearest_player: Player = null
	var min_dist: float = INF
	
	for player in players:
		# Don't target the shooter or dead players
		if player.name.to_int() != owner_peer_id and not player.dead:
			var dist = global_position.distance_to(player.global_position)
			if dist < min_dist:
				min_dist = dist
				nearest_player = player
				
	return nearest_player

func _on_body_entered(body: Node) -> void:
	if not is_multiplayer_authority():
		return
	
	# Handle player collision
	if body is Player and body.name.to_int() != owner_peer_id:
		body.take_damage(damage, owner_peer_id)
		var shooter_player = _get_shooter_player()
		if shooter_player and shooter_player.has_method("play_hit_sound_rpc"):
			shooter_player.rpc("play_hit_sound_rpc")
	
	# Handle bouncing or destruction
	if bounce <= 0:
		call_deferred("queue_free")
	else:
		bounce -= 1

func _get_shooter_player() -> Player:
	var players = get_tree().get_nodes_in_group("player")
	for player in players:
		if player.name.to_int() == owner_peer_id:
			return player
	return null
