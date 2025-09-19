## Network Manager Singleton
## Handles all multiplayer networking, player management, and scene transitions
extends Node

# Signals
signal connection_status_changed(status: String)
signal error(message: String)
signal players_updated(players: Dictionary)
signal all_in_game
signal arena_selected(arena_path: String)

# Scene paths (loaded on demand to avoid null PackedScene issues)
const MENU_SCENE_PATH = "res://scenes/menu/main_menu.tscn"
const LOBBY_SCENE_PATH = "res://scenes/menu/lobby.tscn"
const GAME_SCENE_PATH = "res://scenes/game.tscn"
const BIDDING_SCENE_PATH = "res://scenes/bidding/bidding_menu.tscn"
const WINNING_SCENE_PATH = "res://scenes/menu/winning_display.tscn"

var player_name: String = ""
var peer: SteamMultiplayerPeer
var players: Dictionary = {}
var game_started: bool = false
var game_version: String
var _pending_scene: PackedScene

# Player status constants
enum PlayerStatus {
	CONNECTING,    # In lobby but not registered yet
	REGISTERED,    # Fully registered and ready
	DISCONNECTED   # Disconnected
}

func _ready() -> void:
	# Connect multiplayer signals
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	
	# Get game version from project settings
	game_version = ProjectSettings.get_setting("application/config/version", "unknown")
	
	# Initialize networking state
	_reset_networking_state()

## Reset networking state to clean defaults
func _reset_networking_state() -> void:
	players.clear()
	game_started = false
	peer = null

func _process(_delta: float) -> void:
	if multiplayer.multiplayer_peer and multiplayer.is_server():
		if get_all_in_game() and not game_started:
			game_started = true
			emit_signal("all_in_game")

func host() -> void:
	peer = SteamMultiplayerPeer.new()
	var result = peer.create_host(0)
	if result != OK:
		emit_signal("error", "Failed to create host")
		return
	
	multiplayer.multiplayer_peer = peer
	register_player(player_name, Steam.getSteamID())

func join_lobby(lobby_id: int) -> void:
	peer = SteamMultiplayerPeer.new()
	var owner_id := Steam.getLobbyOwner(lobby_id)
	
	var err: Error = peer.create_client(owner_id, 0)
	if err != OK:
		emit_signal("error", "Failed to connect to lobby host")
		return
	
	multiplayer.multiplayer_peer = peer

func disconnect_from_server() -> void:
	if multiplayer.multiplayer_peer:
		if peer:
			peer.close()
		multiplayer.multiplayer_peer = null
	
	_reset_networking_state()
	_change_scene(MENU_SCENE_PATH)
	emit_signal("players_updated", players)

func is_server() -> bool:
	return multiplayer.multiplayer_peer != null and multiplayer.is_server()

func get_players() -> Dictionary:
	return players.duplicate(true)

func get_username(peer_id: int) -> String:
	if players.has(peer_id) and typeof(players[peer_id]) == TYPE_DICTIONARY:
		return players[peer_id].get("username", "")
	return ""

func get_all_in_game() -> bool:
	if players.is_empty():
		return false
	
	for player_id in players:
		var player_data = players[player_id]
		if typeof(player_data) == TYPE_DICTIONARY and not player_data.get("in_game", false):
			return false
	return true

func get_all_players_registered() -> bool:
	if players.is_empty():
		return false
	
	for player_id in players:
		var player_data = players[player_id]
		if typeof(player_data) == TYPE_DICTIONARY:
			var status = player_data.get("status", PlayerStatus.CONNECTING)
			if status != PlayerStatus.REGISTERED:
				return false
		else:
			return false
	return true

# Server Callbacks
func _on_peer_connected(id: int) -> void:
	emit_signal("connection_status_changed", "Peer %d connected" % id)
	# Add player with CONNECTING status initially (will be updated when they register)
	if multiplayer.is_server():
		players[id] = {
			"username": "Connecting...", 
			"in_game": false, 
			"status": PlayerStatus.CONNECTING, 
			"steam_id": 0
		}
		_broadcast_players()

func _on_peer_disconnected(id: int) -> void:
	emit_signal("connection_status_changed", "Peer %d disconnected" % id)
	if multiplayer.is_server() and players.has(id):
		players.erase(id)
		_broadcast_players()

# Client Callbacks
func _on_connected_to_server() -> void:
	emit_signal("connection_status_changed", "Connected to server as %s" % player_name)
	players.clear()
	# Send version to server for validation first
	rpc_id(1, "check_version", game_version)

func _on_connection_failed() -> void:
	emit_signal("error", GameConfig.get_error_message("connection_failed"))

func _on_server_disconnected() -> void:
	emit_signal("connection_status_changed", "Server disconnected")
	players.clear()
	emit_signal("players_updated", players)
	disconnect_from_server()


@rpc("authority", "call_local")
func change_to_bidding() -> void:
	# Add small delay to ensure all clients are ready for scene transition
	await get_tree().create_timer(GameConfig.SCENE_TRANSITION_DELAY).timeout
	_change_scene(BIDDING_SCENE_PATH)

@rpc("authority", "call_local")
func change_to_winning() -> void:
	_change_scene(WINNING_SCENE_PATH)

@rpc("authority", "call_local")
func change_to_lobby() -> void:
	_change_scene(LOBBY_SCENE_PATH)

@rpc("authority", "call_local")
func start_game() -> void:
	_change_scene(GAME_SCENE_PATH)


@rpc("any_peer", "call_local")
func leave_lobby() -> void:
	if peer:
		peer.close()
		multiplayer.multiplayer_peer = null
	_reset_networking_state()
	_change_scene(MENU_SCENE_PATH)

# Removed unnecessary lobby RPCs - Steam handles all lobby messaging directly

@rpc("any_peer")
func register_player(username: String, steam_id: int = 0) -> void:
	if not multiplayer.is_server():
		return
	
	var sender_id: int = multiplayer.get_remote_sender_id()
	sender_id = 1 if sender_id == 0 else sender_id
	
	# Use provided steam_id or get it if not provided
	if steam_id == 0:
		steam_id = Steam.getSteamID() if sender_id == 1 else 0
	
	players[sender_id] = {
		"username": username.strip_edges(), 
		"in_game": false, 
		"status": PlayerStatus.REGISTERED,
		"steam_id": steam_id
	}
	_broadcast_players()
	
	# Sync lobby config to newly joined player
	if is_server():
		rpc_id(sender_id, "sync_lobby_config", LobbyConfig.get_config_data())

@rpc("authority", "call_local")
func sync_players(updated: Dictionary) -> void:
	players = updated.duplicate(true)
	emit_signal("players_updated", players)

@rpc("any_peer", "call_local")
func request_set_self_in_game(value: bool) -> void:
	if not multiplayer.is_server():
		return
	var id: int = multiplayer.get_remote_sender_id()
	id = 1 if id == 0 else id
	
	if players.has(id):
		var entry = players[id]
		if typeof(entry) == TYPE_DICTIONARY:
			entry["in_game"] = value
			players[id] = entry
			rpc("sync_players", players)

@rpc("any_peer", "call_local")
func set_player_in_game(player_id: int, value: bool) -> void:
	if not multiplayer.is_server():
		return
	players[player_id].in_game = value
	rpc("sync_players", players)

@rpc("any_peer")
func check_version(client_version: String) -> void:
	if not multiplayer.is_server():
		return
		
	var sender_id: int = multiplayer.get_remote_sender_id()
	
	if client_version != game_version:
		print("Version mismatch: Server has %s, Client %d has %s" % [game_version, sender_id, client_version])
		rpc_id(sender_id, "version_mismatch", game_version)
		# Disconnect the client
		multiplayer.multiplayer_peer.disconnect_peer(sender_id)
	else:
		rpc_id(sender_id, "version_accepted")

@rpc("authority")
func version_mismatch(server_version: String) -> void:
	var error_msg = GameConfig.get_error_message("version_mismatch", [server_version, game_version])
	emit_signal("error", error_msg)
	disconnect_from_server()

@rpc("authority")
func version_accepted() -> void:
	var my_steam_id = Steam.getSteamID()
	rpc_id(1, "register_player", player_name, my_steam_id)

@rpc("authority", "call_local")
func sync_arena_selection(arena_path: String) -> void:
	emit_signal("arena_selected", arena_path)

@rpc("authority", "call_local")
func sync_lobby_config(config_data: Dictionary) -> void:
	LobbyConfig.apply_config_data(config_data)

func _broadcast_players() -> void:
	rpc("sync_players", players)

func _change_scene(new_scene) -> void:
	var scene: PackedScene = null
	# Allow passing either a preloaded PackedScene or a String path
	match typeof(new_scene):
		TYPE_OBJECT:
			if new_scene is PackedScene:
				scene = new_scene
		TYPE_STRING:
			if String(new_scene).is_empty():
				push_error("_change_scene called with empty path")
				return
			var loaded = load(new_scene)
			if loaded is PackedScene:
				scene = loaded

	if scene == null:
		push_error("_change_scene: Provided scene is null or invalid. Aborting scene change.")
		return
	# Defer scene change to avoid switching during peer teardown
	_pending_scene = scene
	call_deferred("_apply_scene_change")

func _apply_scene_change() -> void:
	if _pending_scene == null:
		return
	get_tree().change_scene_to_packed(_pending_scene)
	_pending_scene = null
