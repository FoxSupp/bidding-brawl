extends Node

signal connection_status_changed(status: String)
signal error(message: String)
signal players_updated(players: Dictionary)
signal all_in_game

const MENU_SCENE = preload("res://scenes/main_menu.tscn")
const LOBBY_SCENE = preload("res://scenes/lobby.tscn")
const GAME_SCENE = preload("res://scenes/game.tscn")


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

func _process(delta: float) -> void:
	if multiplayer.multiplayer_peer:
		if multiplayer.is_server() and get_all_in_game() and !game_started:
			game_started = true
			emit_signal("all_in_game")

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
	register_player(player_name)
	#players[multiplayer.get_unique_id()] = {'username':player_name, 'in_game': false}
	_change_scene(LOBBY_SCENE)

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
	return players.get(peer_id, "")

func get_all_in_game() -> bool:
	if players.is_empty():
		return false
	for player in players:
		if players[player]["in_game"] == false:
			return false
	return true

# Server Callbacks
func _on_peer_connected(id: int) -> void:
	emit_signal("connection_status_changed", "Peer %d connected" % id)
	# Client will register itself via RPC with username.

func _on_peer_disconnected(id: int) -> void:
	emit_signal("connection_status_changed", "Peer %d disconnected" % id)
	if multiplayer.is_server():
		if players.has(id):
			players.erase(id)
			_broadcast_players()

# Client Callbacks
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

@rpc("authority", "call_local")
func start_game():
	_change_scene(GAME_SCENE)

# Clients call this on the server to register their username
@rpc("any_peer")
func register_player(username: String) -> void:
        if not multiplayer.is_server():
                return
        var sender_id := multiplayer.get_remote_sender_id()
        sender_id = 1 if sender_id == 0 else sender_id
       players[sender_id] = {
               "username": username.strip_edges(),
               "in_game": false,
               "wins": 0,
               "losses": 0,
               "win_streak": 0,
               "loss_streak": 0,
       }
        _broadcast_players()

# Server sends current players to everyone (and itself)
func _broadcast_players() -> void:
	rpc("sync_players", players)

@rpc("authority", "call_local")
func sync_players(updated: Dictionary) -> void:
	players = updated.duplicate(true)
	emit_signal("players_updated", players)

@rpc("any_peer", "call_local")
func request_set_self_in_game(value: bool) -> void:
        if not multiplayer.is_server():
                return
        var id := multiplayer.get_remote_sender_id()
        id = 1 if id == 0 else id
	
	if players.has(id):
		var entry = players[id]
		if typeof(entry) == TYPE_DICTIONARY:
                        entry["in_game"] = value
                        players[id] = entry
                        rpc("sync_players", players)

# Server records match results and broadcasts updated stats
func record_match_result(winner_id: int) -> void:
       if not multiplayer.is_server():
               return
       for peer_id in players.keys():
               var entry = players[peer_id]
               if typeof(entry) != TYPE_DICTIONARY:
                       continue
               entry["in_game"] = false
               if peer_id == winner_id:
                       entry["wins"] += 1
                       entry["win_streak"] += 1
                       entry["loss_streak"] = 0
               else:
                       entry["losses"] += 1
                       entry["loss_streak"] += 1
                       entry["win_streak"] = 0
               players[peer_id] = entry
       game_started = false
       rpc("sync_players", players)

func _change_scene(scene: PackedScene) -> void:
	get_tree().change_scene_to_packed(scene)
