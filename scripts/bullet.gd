extends RigidBody2D

@export var speed: float = 1000.0
@export var dir: Vector2
@export var player_id: int

const DAMAGE: int = 1

func _ready() -> void:
	linear_velocity = dir * speed

func _on_body_entered(body: Node) -> void:
	if not is_multiplayer_authority():
		return
	
	if body is Player:
		body.take_damage(DAMAGE, player_id)
	
	var spawner: Node = get_tree().root.get_node_or_null("Game/BulletSpawner")
	if spawner and spawner.has_method("despawn"):
		spawner.despawn(self)
	else:
		call_deferred("queue_free")