extends Node2D

var _spawned: = {}

func _ready() -> void:
	if has_node("/root/NetworkManager"):
		var nm = get_node("/root/NetworkManager")
		nm.players_updated.connect(_on_players_updated)
	if multiplayer.is_server():
		_spawn_all_current()

func _spawn_all_current() -> void:
	var nm = get_node("/root/NetworkManager")
	for peer_id in nm.players:
		if not _spawned.has(peer_id):
			_spawn_player(int(peer_id))

func _spawn_player(peer_id: int) -> void:
	var player_scene = preload("res://scenes/player.tscn")
	var player_instance = player_scene.instantiate()
	player_instance.name = str(peer_id)
	player_instance.position = Vector2(randi() % 4 * 100, 0)
	add_child(player_instance, true)
	_spawned[peer_id] = true

func _on_players_updated(_players: Dictionary) -> void:
	if multiplayer.is_server():
		_spawn_all_current()
