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
	
	_add_players_to_session()
	for player_id in NetworkManager.players:
		var player_instance: Node = PLAYER_SCENE.instantiate()
		player_instance.name = str(player_id)
		
		if spawn_points:
			var spawn_point: Node = spawn_points.pop_back()
			player_instance.position = spawn_point.position
			spawn_point.queue_free()
		
		players.add_child(player_instance)
		player_instance.died.connect(_on_player_died)

func _add_players_to_session() -> void:
	for peer_id in NetworkManager.players:
		if not SessionManager.player_stats.has(peer_id):
			SessionManager.newPlayer(peer_id)


func add_score(score: int, shooter_id: int) -> void:
	
	var target_player: Node = players.get_node_or_null(str(shooter_id))
	if target_player:
		target_player.add_score(score)

func _on_player_died(_player_id: int) -> void:
	var alive_players: Array[Node] = players.get_children().filter(func(p): return not p.dead)
	if alive_players.size() == 1:
		print("Game Over! Winner: ", alive_players[0].name)
		_end_game(alive_players[0].name.to_int())

func _end_game(winner_id: int):
	await get_tree().create_timer(2).timeout
	SessionManager.win(winner_id)
	# Clean up all bullets before despawning players to prevent multiplayer despawn errors
	var projectiles_node = get_node_or_null("Projectiles")
	if projectiles_node:
		for bullet in projectiles_node.get_children():
			bullet.queue_free()
		# Wait a frame to ensure bullets are properly cleaned up
		await get_tree().process_frame
	
	for player in players.get_children():
		player.input_synch.get_node("InputSynch").public_visibility = false
		player.despawn_player()
		NetworkManager.rpc_id(1, "set_player_in_game", player.name.to_int(), false)

	NetworkManager.game_started = false
	await get_tree().create_timer(1).timeout
	if multiplayer.is_server():
		NetworkManager.rpc("change_to_bidding")
