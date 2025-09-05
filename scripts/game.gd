extends Node2D

@onready var spawn_positions: Node2D = $SpawnPositions
@onready var players: Node = $Players

const PLAYER_SCENE = preload("res://scenes/player.tscn")

func _ready() -> void:
	NetworkManager.all_in_game.connect(_spawn_all_players)
	NetworkManager.rpc_id(1, "request_set_self_in_game", true)

func _spawn_all_players() -> void:
	if not multiplayer.is_server():
		return
	
	var spawn_points: Array[Node] = spawn_positions.get_children()
	
	for player_id in NetworkManager.players:
		var player_instance: Node = PLAYER_SCENE.instantiate()
		player_instance.name = str(player_id)
		
		if spawn_points:
			var spawn_point: Node = spawn_points.pop_back()
			player_instance.position = spawn_point.position
			spawn_point.queue_free()
		
		players.add_child(player_instance)
		player_instance.died.connect(_on_player_died)

func add_score(score: int, shooter_id: int) -> void:
	var target_player: Node = players.get_node_or_null(str(shooter_id))
	if target_player:
		target_player.add_score(score)

func _on_player_died(_player_id: int) -> void:
	var alive_players: Array[Node] = players.get_children().filter(func(p): return not p.dead)
	
	if alive_players.size() == 1:
		print("Game Over! Winner: ", alive_players[0].name)
