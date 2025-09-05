extends Node



signal connection_status_changed(status: String)
signal error(message: String)
signal players_updated(players: Dictionary)


const MENU_SCENE = preload("res://scenes/main_menu.tscn")
const LOBBY_SCENE = preload("res://scenes/lobby.tscn")


var player_name: String = ""
var peer: ENetMultiplayerPeer
var players: Dictionary = {}

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func host(port: int, username: String) -> void:
	if username.strip_edges() == "":
		emit_signal("error", "Username is required")
		return
	player_name = username.strip_edges()
	peer = ENetMultiplayerPeer.new()
	var err := peer.create_server(port, 32)
	if err != OK:
		emit_signal("error", "Failed to host on port %d (error %d)" % [port, err])
		return
	multiplayer.multiplayer_peer = peer
	# Register host as first player and broadcast
	players.clear()
	players[multiplayer.get_unique_id()] = player_name
	get_tree().change_scene_to_packed(LOBBY_SCENE)
	_broadcast_players()

func join(ip: String, port: int, username: String) -> void:
	if username.strip_edges() == "":
		emit_signal("error", "Username is required")
		return
	if ip.strip_edges() == "":
		emit_signal("error", "Server IP is required")
		return
	player_name = username.strip_edges()
	peer = ENetMultiplayerPeer.new()
	var err := peer.create_client(ip.strip_edges(), port)
	if err != OK:
		emit_signal("error", "Failed to connect to %s:%d (error %d)" % [ip, port, err])
		return
	multiplayer.multiplayer_peer = peer
	get_tree().change_scene_to_packed(LOBBY_SCENE)

	

func disconnect_from_server() -> void:
	if multiplayer.multiplayer_peer:
		peer.close()
		multiplayer.multiplayer_peer = null
	players.clear()
	get_tree().change_scene_to_packed(MENU_SCENE)
	emit_signal("players_updated", players)

func is_server() -> bool:
	return multiplayer.is_server()

func get_players() -> Dictionary:
	return players.duplicate(true)

func get_username(peer_id: int) -> String:
	return players.get(peer_id, "")

func _on_peer_connected(id: int) -> void:
	emit_signal("connection_status_changed", "Peer %d connected" % id)
	# Client will register itself via RPC with username.

func _on_peer_disconnected(id: int) -> void:
	emit_signal("connection_status_changed", "Peer %d disconnected" % id)
	if multiplayer.is_server():
		if players.has(id):
			players.erase(id)
			_broadcast_players()

func _on_connected_to_server() -> void:
	emit_signal("connection_status_changed", "Connected to server as %s" % player_name)
	players.clear()
	# Register this client's username with the server once connected
	rpc_id(1, "register_player", player_name)

func _on_connection_failed() -> void:
	emit_signal("error", "Connection failed")

func _on_server_disconnected() -> void:
	emit_signal("connection_status_changed", "Server disconnected")
	players.clear()
	emit_signal("players_updated", players)
	disconnect_from_server()

# Clients call this on the server to register their username
@rpc("any_peer")
func register_player(username: String) -> void:
	if not multiplayer.is_server():
		return
	var sender_id := multiplayer.get_remote_sender_id()
	players[sender_id] = username.strip_edges()
	_broadcast_players()

# Server sends current players to everyone (and itself)
func _broadcast_players() -> void:
	rpc("sync_players", players)
	#sync_players(players) # also update locally without relying on call_local

@rpc("call_local", "authority")
func sync_players(updated: Dictionary) -> void:
	players = updated.duplicate(true)
	emit_signal("players_updated", players)

# start_game removed as part of lobby-only reset

# load_game_scene removed

# notify_game_scene_ready removed
