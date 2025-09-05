extends Node

signal connection_status_changed(status: String)
signal error(message: String)
signal players_updated(players: Dictionary)
signal all_in_game

const MENU_SCENE = preload("res://scenes/main_menu.tscn")
const LOBBY_SCENE = preload("res://scenes/lobby.tscn")
const GAME_SCENE = preload("res://scenes/game.tscn")
const MAX_PLAYERS: int = 32

var player_name: String = ""
var peer: ENetMultiplayerPeer
var players: Dictionary = {}
var game_started: bool = false

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func _process(_delta: float) -> void:
	if multiplayer.multiplayer_peer and multiplayer.is_server():
		if get_all_in_game() and not game_started:
			game_started = true
			emit_signal("all_in_game")

func host(port: int, username: String) -> void:
	var clean_username: String = username.strip_edges()
	if clean_username.is_empty():
		emit_signal("error", "Username is required")
		return
	
	player_name = clean_username
	peer = ENetMultiplayerPeer.new()
	var err: Error = peer.create_server(port, MAX_PLAYERS)
	if err != OK:
		emit_signal("error", "Failed to host on port %d (error %d)" % [port, err])
		return
	
	multiplayer.multiplayer_peer = peer
	players.clear()
	register_player(player_name)
	_change_scene(LOBBY_SCENE)

func join(ip: String, port: int, username: String) -> void:
	var clean_username: String = username.strip_edges()
	var clean_ip: String = ip.strip_edges()
	
	if clean_username.is_empty():
		emit_signal("error", "Username is required")
		return
	
	if clean_ip.is_empty():
		emit_signal("error", "Server IP is required")
		return
	
	player_name = clean_username
	peer = ENetMultiplayerPeer.new()
	var err: Error = peer.create_client(clean_ip, port)
	if err != OK:
		emit_signal("error", "Failed to connect to %s:%d (error %d)" % [clean_ip, port, err])
		return
	
	multiplayer.multiplayer_peer = peer
	_change_scene(LOBBY_SCENE)

func disconnect_from_server() -> void:
	if multiplayer.multiplayer_peer:
		peer.close()
		multiplayer.multiplayer_peer = null
	players.clear()
	_change_scene(MENU_SCENE)
	emit_signal("players_updated", players)

func is_server() -> bool:
	return multiplayer.is_server()

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

# Server Callbacks
func _on_peer_connected(id: int) -> void:
	emit_signal("connection_status_changed", "Peer %d connected" % id)

func _on_peer_disconnected(id: int) -> void:
	emit_signal("connection_status_changed", "Peer %d disconnected" % id)
	if multiplayer.is_server() and players.has(id):
		players.erase(id)
		_broadcast_players()

# Client Callbacks
func _on_connected_to_server() -> void:
	emit_signal("connection_status_changed", "Connected to server as %s" % player_name)
	players.clear()
	rpc_id(1, "register_player", player_name)

func _on_connection_failed() -> void:
	emit_signal("error", "Connection failed")

func _on_server_disconnected() -> void:
	emit_signal("connection_status_changed", "Server disconnected")
	players.clear()
	emit_signal("players_updated", players)
	disconnect_from_server()

@rpc("authority", "call_local")
func start_game() -> void:
	_change_scene(GAME_SCENE)

@rpc("any_peer")
func register_player(username: String) -> void:
	if not multiplayer.is_server():
		return
	
	var sender_id: int = multiplayer.get_remote_sender_id()
	sender_id = 1 if sender_id == 0 else sender_id
	players[sender_id] = {"username": username.strip_edges(), "in_game": false}
	_broadcast_players()

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

func _broadcast_players() -> void:
	rpc("sync_players", players)

func _change_scene(scene: PackedScene) -> void:
	get_tree().change_scene_to_packed(scene)
