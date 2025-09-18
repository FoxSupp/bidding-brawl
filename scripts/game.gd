## Game Scene Controller
## Manages arena loading, player spawning, and game flow
extends Node2D

# Scene references
var spawn_positions: Node
@onready var players: Node = $Players
@onready var scoreboard: Node = $Scoreboard

# Constants
const PLAYER_SCENE = preload("res://scenes/player.tscn")

func _ready() -> void:
	# All clients (including server) connect to the signal
	if not NetworkManager.arena_selected.is_connected(_load_arena):
		NetworkManager.arena_selected.connect(_load_arena)
	
	# Connect to all_in_game signal for both arena selection and player spawning
	NetworkManager.all_in_game.connect(_on_all_players_in_game)
	NetworkManager.rpc_id(1, "request_set_self_in_game", true)

	add_to_group("game")


func _process(_delta: float) -> void:
	# Handle scoreboard display for the local player
	var local_player = _get_local_player()
	if local_player and local_player.input_synch.scoreboard_show:
		if not scoreboard.visible:
			scoreboard.show_scoreboard()
	else:
		if scoreboard.visible:
			scoreboard.hide_scoreboard()

func _get_local_player() -> Node:
	var local_id = multiplayer.get_unique_id()
	return players.get_node_or_null(str(local_id))


func _on_all_players_in_game() -> void:
	if not multiplayer.is_server():
		return
	
	# First select and sync the arena to all players
	_select_and_sync_arena()
	# Then spawn all players (with a small delay to ensure arena is loaded)
	call_deferred("_spawn_all_players")

func _select_and_sync_arena() -> void:
	var random_arena_path = GameConfig.get_random_arena()
	if random_arena_path.is_empty():
		push_error("No arena scenes available!")
		return
		
	NetworkManager.rpc("sync_arena_selection", random_arena_path)

func _load_arena(arena_path: String) -> void:
	var arena_scene = load(arena_path)
	if not arena_scene:
		var error_msg = GameConfig.get_error_message("arena_load_failed", [arena_path])
		push_error(error_msg)
		return
	
	var arena_instance = arena_scene.instantiate()
	add_child(arena_instance)
	spawn_positions = arena_instance.get_node("SpawnPositions")

func _spawn_all_players() -> void:
	# Wait until the Game scene is fully loaded
	await get_tree().process_frame
	
	if not spawn_positions:
		push_error(GameConfig.get_error_message("spawn_positions_null"))
		await get_tree().create_timer(0.1).timeout
		call_deferred("_spawn_all_players")
		return
	
	var spawn_points: Array[Node] = spawn_positions.get_children()
	
	_add_players_to_session()
	for player_id in NetworkManager.players:
		var player_instance: Node = PLAYER_SCENE.instantiate()
		player_instance.name = str(player_id)
		
		if spawn_points:
			var spawn_point: Node = spawn_points.pick_random()
			player_instance.position = spawn_point.position
			spawn_point.queue_free()
			spawn_points.remove_at(spawn_points.find(spawn_point))
		
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
		await get_tree().create_timer(GameConfig.GAME_END_DELAY).timeout
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
			# Check if input_synch exists and is valid before accessing its children
			if is_instance_valid(player.input_synch) and player.input_synch.has_node("InputSynch"):
				var input_synch_node = player.input_synch.get_node("InputSynch")
				if is_instance_valid(input_synch_node):
					input_synch_node.public_visibility = false
			player.call_deferred("despawn_player")
	
	# Update NetworkManager after despawning
	for player_id in player_ids:
		NetworkManager.rpc_id(1, "set_player_in_game", player_id, false)

	NetworkManager.game_started = false
	await get_tree().create_timer(GameConfig.BIDDING_DESPAWN_DELAY).timeout
	if multiplayer.is_server():
		print(SessionManager.player_stats[winner_id]["wins"])
		if SessionManager.player_stats[winner_id]["wins"] >= GameConfig.WIN_COUNT:
			SessionManager.winner = SessionManager.player_stats[winner_id]
			NetworkManager.rpc("change_to_winning")
		else:
			NetworkManager.rpc("change_to_bidding")
