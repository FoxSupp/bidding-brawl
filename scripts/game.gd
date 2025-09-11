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
		await get_tree().create_timer(2).timeout
		_end_game(alive_players[0].name.to_int())

func _end_game(winner_id: int):
	SessionManager.win(winner_id)
	
	# Clean up all bullets before despawning players to prevent multiplayer despawn errors
	var projectiles_node = get_node_or_null("Projectiles")
	if projectiles_node:
		for bullet in projectiles_node.get_children():
			bullet.queue_free()
		await get_tree().process_frame
	
	# Store player data before despawning to avoid accessing deleted nodes
	var player_list = players.get_children()
	var player_ids = []
	for player in player_list:
		player_ids.append(player.name.to_int())
	
	# Despawn all players safely
	for player in player_list:
		if is_instance_valid(player):
			var input_synch_node = player.input_synch.get_node_or_null("InputSynch")
			if input_synch_node and is_instance_valid(input_synch_node):
				input_synch_node.public_visibility = false
			player.despawn_player()
	
	# Update NetworkManager after despawning
	for player_id in player_ids:
		NetworkManager.rpc_id(1, "set_player_in_game", player_id, false)

	NetworkManager.game_started = false
	await get_tree().create_timer(1).timeout
	if multiplayer.is_server():
		NetworkManager.rpc("change_to_bidding")
