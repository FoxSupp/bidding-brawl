extends RigidBody2D

@export var speed: float = 1000.0
@export var damage: int = 1
@export var dir: Vector2
@export var owner_peer_id: int
@export var lifetime: float
@export var bounce: int = 0


func _ready() -> void:
	linear_velocity = dir * speed

func _process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
		# Rotate the bullet to match its current movement direction (falling or rising)
	if linear_velocity.length() > 0:
		rotation = linear_velocity.angle()
	lifetime -= delta
	if lifetime <= 0:
		call_deferred("queue_free")

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
