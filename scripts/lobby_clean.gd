## Clean Lobby Controller
## Simple and robust Steam lobby management
extends Control

# UI References
@onready var timer_start_game: Timer = $TimerStartGame
@onready var label_start_game: Label = $LabelStartGame

# Constants
const PLAYER_SLOT_SCENE = preload("res://scenes/menu/player_slot.tscn")

# Lobby State (minimal)
var lobby_id: int = 0
var lobby_members: Array = []

# Signals
signal lobby_updated

func _ready() -> void:
	_setup_connections()
	_refresh_lobby_list()

func _setup_connections() -> void:
	# Steam signals
	if Steam:
		Steam.lobby_created.connect(_on_lobby_created)
		Steam.lobby_joined.connect(_on_lobby_joined)
		Steam.lobby_match_list.connect(_on_lobby_match_list)
		Steam.lobby_chat_update.connect(_on_lobby_chat_update)
	
	# NetworkManager signals
	NetworkManager.players_updated.connect(_on_players_updated)
	
	# Internal signals
	lobby_updated.connect(_update_lobby_ui)

func _process(_delta: float) -> void:
	if timer_start_game.time_left > 0:
		label_start_game.text = "Game starts in %s" % str(int(timer_start_game.time_left + 1))

#region LOBBY CREATION & JOINING

func create_lobby() -> void:
	if lobby_id != 0:
		push_warning("Already in a lobby!")
		return
	
	if not Steam:
		push_error("Steam not available!")
		return
	
	Steam.createLobby(GameConfig.LOBBY_TYPE, GameConfig.LOBBY_MEMBERS_MAX)

func join_lobby(target_lobby_id: int) -> void:
	if target_lobby_id <= 0:
		push_error("Invalid lobby ID")
		return
	
	if not Steam:
		push_error("Steam not available!")
		return
	
	Steam.joinLobby(target_lobby_id)

func leave_lobby() -> void:
	if lobby_id == 0:
		# Not in a lobby, just go to main menu
		NetworkManager._change_scene(NetworkManager.MENU_SCENE_PATH)
		return
	
	var is_host = _am_i_host()
	_add_chat_message("Leaving lobby...")
	
	# Clean disconnect from NetworkManager first
	NetworkManager.disconnect_from_server()
	
	# Handle Steam lobby
	if is_host:
		_destroy_steam_lobby()
	else:
		_leave_steam_lobby()
	NetworkManager.leave_lobby()
	
	# Go to main menu
	NetworkManager._change_scene(NetworkManager.MENU_SCENE_PATH)

func _destroy_steam_lobby() -> void:
	print("Host destroying lobby ", lobby_id)
	Steam.setLobbyJoinable(lobby_id, false)
	Steam.deleteLobbyData(lobby_id, "name")
	Steam.deleteLobbyData(lobby_id, "bidding")
	Steam.leaveLobby(lobby_id)
	_clear_lobby_state()

func _leave_steam_lobby() -> void:
	print("Client leaving lobby ", lobby_id)
	Steam.leaveLobby(lobby_id)
	_clear_lobby_state()

func _clear_lobby_state() -> void:
	lobby_id = 0
	lobby_members.clear()

func _am_i_host() -> bool:
	if lobby_id == 0 or not Steam:
		return false
	return Steam.getLobbyOwner(lobby_id) == Steam.getSteamID()

#endregion

#region STEAM CALLBACKS

func _on_lobby_created(result: int, created_lobby_id: int) -> void:
	if result != 1:
		push_error("Failed to create lobby")
		return
	
	lobby_id = created_lobby_id
	print("Lobby created: ", lobby_id)
	
	# Setup lobby
	Steam.setLobbyJoinable(lobby_id, true)
	Steam.setLobbyData(lobby_id, "name", Steam.getPersonaName() + "'s Lobby")
	Steam.setLobbyData(lobby_id, "bidding", "brawl")
	
	# Start hosting
	NetworkManager.host()

func _on_lobby_joined(joined_lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
	if response != Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		var error_msg = GameConfig.get_steam_join_fail_message(response)
		push_error("Failed to join lobby: " + error_msg)
		_refresh_lobby_list()
		return
	
	lobby_id = joined_lobby_id
	print("Joined lobby: ", lobby_id)
	
	# Connect to host if not the owner
	if not _am_i_host():
		NetworkManager.join_lobby(lobby_id)
	
	emit_signal("lobby_updated")

func _on_lobby_chat_update(_lobby_id: int, user_id: int, _changer_id: int, state: int) -> void:
	var username = Steam.getFriendPersonaName(user_id)
	
	match state:
		Steam.CHAT_MEMBER_STATE_CHANGE_ENTERED:
			_add_chat_message(username + " joined")
		Steam.CHAT_MEMBER_STATE_CHANGE_LEFT:
			if username != Steam.getPersonaName():  # Don't show our own leave
				_add_chat_message(username + " left")
		Steam.CHAT_MEMBER_STATE_CHANGE_DISCONNECTED:
			_add_chat_message(username + " disconnected")
	
	emit_signal("lobby_updated")

func _on_lobby_match_list(lobbies: Array) -> void:
	# Clear old buttons
	for child in $LobbyList/ScrollContainer/VBoxContainer.get_children():
		child.queue_free()
	
	# Create buttons for valid lobbies
	for lobby in lobbies:
		var lobby_name = Steam.getLobbyData(lobby, "name")
		var lobby_type = Steam.getLobbyData(lobby, "bidding")
		var member_count = Steam.getNumLobbyMembers(lobby)
		
		# Filter valid lobbies
		if lobby_type != "brawl" or lobby_name.is_empty() or member_count <= 0:
			continue
		
		# Create lobby button
		var button = Button.new()
		button.text = "%s (%d/%d players)" % [lobby_name, member_count, GameConfig.LOBBY_MEMBERS_MAX]
		button.size = Vector2(800, 50)
		button.pressed.connect(join_lobby.bind(lobby))
		
		$LobbyList/ScrollContainer/VBoxContainer.add_child(button)



#endregion

#region UI MANAGEMENT

func _update_lobby_ui() -> void:
	if lobby_id == 0:
		$LobbyList.show()
		$Lobby.hide()
		return
	
	$LobbyList.hide()
	$Lobby.show()
	
	_update_lobby_members()
	_update_start_button()

func _update_lobby_members() -> void:
	# Clear existing slots
	for child in $Lobby/ContainerPlayers.get_children():
		child.queue_free()
	
	# Get current members
	lobby_members.clear()
	if lobby_id == 0:
		return
	
	var member_count = Steam.getNumLobbyMembers(lobby_id)
	for i in range(member_count):
		var member_id = Steam.getLobbyMemberByIndex(lobby_id, i)
		var member_name = Steam.getFriendPersonaName(member_id)
		lobby_members.append({"steam_id": member_id, "steam_name": member_name})
		
		# Create UI slot
		var slot = PLAYER_SLOT_SCENE.instantiate()
		$Lobby/ContainerPlayers.add_child(slot)
		slot.call_deferred("set_player_data", member_name, NetworkManager.PlayerStatus.REGISTERED)

func _update_start_button() -> void:
	var can_start = _am_i_host() and lobby_members.size() > 0
	$Lobby/ButtonStartGame.disabled = not can_start

func _add_chat_message(message: String) -> void:
	var chat = get_node_or_null("Lobby/ChatBackground/Chat")
	if chat:
		chat.text += message + "\n"

func _refresh_lobby_list() -> void:
	if Steam:
		Steam.addRequestLobbyListDistanceFilter(GameConfig.LOBBY_DISTANCE_FILTER)
		Steam.requestLobbyList()

#endregion

#region BUTTON CALLBACKS

func _on_button_host_pressed() -> void:
	create_lobby()

func _on_button_lobby_list_pressed() -> void:
	_refresh_lobby_list()

func _on_button_back_pressed() -> void:
	leave_lobby()

func _on_button_start_game_pressed() -> void:
	if not _am_i_host():
		return
	
	# Start countdown
	label_start_game.show()
	timer_start_game.start(3.0)
	await timer_start_game.timeout
	
	# Start game
	if NetworkManager.is_server():
		NetworkManager.rpc("start_game")

#endregion

#region NETWORK CALLBACKS

func _on_players_updated(_players: Dictionary) -> void:
	if $Lobby.visible:
		_update_lobby_ui()

#endregion
