extends RigidBody2D

@export var speed: float = 1000.0
@export var damage: int = 1
@export var dir: Vector2
@export var owner_peer_id: int
@export var lifetime: float


func _ready() -> void:
	linear_velocity = dir * speed

func _process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	lifetime -= delta
	if lifetime <= 0:
		call_deferred("queue_free")

func _on_body_entered(body: Node) -> void:
	if not is_multiplayer_authority():
		return
	
	if body is Player:
		body.take_damage(damage, owner_peer_id)
	
	call_deferred("queue_free")
