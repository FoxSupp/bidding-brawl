## Clean Lobby Controller
## Simple and robust Steam lobby management
extends Control

# UI References
@onready var timer_start_game: Timer = $TimerStartGame
@onready var label_start_game: Label = $LabelStartGame

# Constants
const PLAYER_SLOT_SCENE = preload("res://scenes/menu/player_slot.tscn")
const LOBBY_BUTTON_SCENE = preload("res://scenes/menu/lobby_button.tscn")
# Lobby State (minimal)


# Signals
signal lobby_updated

func _ready() -> void:
	_setup_connections()
	_refresh_lobby_list()

func _setup_connections() -> void:
	# Steam signals
	if Steam:
		Steam.lobby_created.connect(_on_lobby_created)
		Steam.lobby_match_list.connect(_on_lobby_match_list)
		Steam.lobby_chat_update.connect(_on_lobby_chat_update)
		Steam.lobby_joined.connect(_on_lobby_joined)
	
	# NetworkManager signals
	NetworkManager.players_updated.connect(_on_players_updated)
	
	# Internal signals
	lobby_updated.connect(_update_lobby_ui)

func _process(_delta: float) -> void:
	if timer_start_game.time_left > 0:
		label_start_game.text = "Game starts in %s" % str(int(timer_start_game.time_left + 1))

#region LOBBY CREATION & JOINING

func create_lobby() -> void:
	if Steamworks.lobby_id != 0:
		push_warning("Already in a lobby!")
		return
	
	if not Steam:
		push_error("Steam not available!")
		return
	
	Steam.createLobby(GameConfig.LOBBY_TYPE, GameConfig.LOBBY_MEMBERS_MAX)

func leave_lobby() -> void:
	if Steamworks.lobby_id == 0:
		# Not in a lobby, just go to main menu
		NetworkManager._change_scene(NetworkManager.MENU_SCENE_PATH)
		return
	
	var is_host = Steamworks._am_i_host()
	_add_chat_message("Leaving lobby...")
	
	# Clean disconnect from NetworkManager first
	NetworkManager.disconnect_from_server()
	
	# Handle Steam lobby (do not change scene here; NetworkManager already did)
	if is_host:
		_destroy_steam_lobby()
	else:
		_leave_steam_lobby()

func get_lobbies_with_friends() -> Dictionary:
	var results: Dictionary = {}

	for i in range(0, Steam.getFriendCount()):
		var steam_id: int = Steam.getFriendByIndex(i, Steam.FRIEND_FLAG_IMMEDIATE)
		var game_info: Dictionary = Steam.getFriendGamePlayed(steam_id)

		if game_info.is_empty():
			# This friend is not playing a game
			continue
		else:
			# They are playing a game, check if it's the same game as ours
			var app_id: int = game_info['id']
			var lobby = game_info['lobby']

			if app_id != Steam.getAppID() or lobby == 0:
				# Either not in this game, or not in a lobby
				continue

			results[steam_id] = lobby

	return results

func _destroy_steam_lobby() -> void:
	print("Host destroying lobby ", Steamworks.lobby_id)
	Steam.setLobbyJoinable(Steamworks.lobby_id, false)
	Steam.deleteLobbyData(Steamworks.lobby_id, "name")
	Steam.deleteLobbyData(Steamworks.lobby_id, "bidding")
	Steam.leaveLobby(Steamworks.lobby_id)
	_clear_lobby_state()

func _leave_steam_lobby() -> void:
	print("Client leaving lobby ", Steamworks.lobby_id)
	Steam.leaveLobby(Steamworks.lobby_id)
	_clear_lobby_state()

func _clear_lobby_state() -> void:
	Steamworks.lobby_id = 0
	Steamworks.lobby_members.clear()
#endregion

#region STEAM CALLBACKS

func _on_lobby_created(result: int, created_lobby_id: int) -> void:
	if result != 1:
		push_error("Failed to create lobby")
		return
	
	Steamworks.lobby_id = created_lobby_id

	print("Lobby created: ", Steamworks.lobby_id)
	
	# Setup lobby
	Steam.setLobbyJoinable(Steamworks.lobby_id, true)
	Steam.setLobbyData(Steamworks.lobby_id, "name", Steam.getPersonaName() + "'s Lobby")
	Steam.setLobbyData(Steamworks.lobby_id, "bidding", "brawl")
	Steamworks.lobby_members.clear()
	Steamworks.lobby_members.append({"steam_id": Steam.getSteamID(), "steam_name": Steam.getPersonaName()})
	# Start hosting
	NetworkManager.host()

func _on_lobby_joined(joined_lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
	if response != Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		var error_msg = GameConfig.get_steam_join_fail_message(response)
		push_error("Failed to join lobby: " + error_msg)
		#_refresh_lobby_list()
		return
	
	Steamworks.lobby_id = joined_lobby_id
	print("Joined lobby: ", Steamworks.lobby_id)
	
	# Connect to host if not the owner
	if not Steamworks._am_i_host():
		NetworkManager.join_lobby(Steamworks.lobby_id)
	
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
	
	if GameConfig.SHOW_ONLY_FRIENDS_LOBBIES:
		var friend_lobbies = get_lobbies_with_friends()
		if friend_lobbies.size() <= 0:
			var text = Label.new()
			text.text = "No lobbies found"
			text.add_theme_font_size_override("font_size", 32)
			text.size = Vector2(800, 50)
			$LobbyList/ScrollContainer/VBoxContainer.add_child(text)
			return
		for friend_id in friend_lobbies:
			var friend_lobby_id = friend_lobbies[friend_id]
			var friend_name = Steam.getFriendPersonaName(friend_id)
			var member_count = Steam.getNumLobbyMembers(friend_lobby_id)
			
			# Create lobby button
			var lobby_button = LOBBY_BUTTON_SCENE.instantiate()
			lobby_button.setup_button_data("%s's Lobby (%d/%d players)" % [friend_name, member_count, GameConfig.LOBBY_MEMBERS_MAX], friend_lobby_id)
			$LobbyList/ScrollContainer/VBoxContainer.add_child(lobby_button)
	else:
		if lobbies.size() <= 0:
			var text = Label.new()
			text.text = "No lobbies found"
			text.add_theme_font_size_override("font_size", 32)
			text.size = Vector2(800, 50)
			$LobbyList/ScrollContainer/VBoxContainer.add_child(text)
			return
		# Create buttons for valid lobbies
		for lobby in lobbies:
			var lobby_name = Steam.getLobbyData(lobby, "name")
			var lobby_type = Steam.getLobbyData(lobby, "bidding")
			var member_count = Steam.getNumLobbyMembers(lobby)
			
			# Filter valid lobbies
			if lobby_type != "brawl" or lobby_name.is_empty() or member_count <= 0:
				pass
			
			# Create lobby button
			var lobby_button = LOBBY_BUTTON_SCENE.instantiate()
			lobby_button.setup_button_data("%s (%d/%d players)" % [lobby_name, member_count, GameConfig.LOBBY_MEMBERS_MAX], lobby)
			$LobbyList/ScrollContainer/VBoxContainer.add_child(lobby_button)

#endregion

#region UI MANAGEMENT

func _update_lobby_ui() -> void:
	if Steamworks.lobby_id == 0:
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
	Steamworks.lobby_members.clear()
	if Steamworks.lobby_id == 0:
		return
	
	var member_count = Steam.getNumLobbyMembers(Steamworks.lobby_id)
	for i in range(member_count):
		var member_id = Steam.getLobbyMemberByIndex(Steamworks.lobby_id, i)
		var member_name = Steam.getFriendPersonaName(member_id)
		Steamworks.lobby_members.append({"steam_id": member_id, "steam_name": member_name})
		
		# Create UI slot
		var slot = PLAYER_SLOT_SCENE.instantiate()
		slot.name = str(member_id)
		$Lobby/ContainerPlayers.add_child(slot)
		
		var player_status = NetworkManager.PlayerStatus.CONNECTING
		var network_players = NetworkManager.get_players()
		
		for player_id in network_players:
			var player_data = network_players[player_id]
			if typeof(player_data) == TYPE_DICTIONARY and player_data.get("steam_id", 0) == member_id:
				player_status = player_data.get("status", NetworkManager.PlayerStatus.REGISTERED)
				break
		
		slot.call_deferred("set_player_data", member_name, player_status)

func _update_start_button() -> void:
	var can_start = false
	
	if Steamworks._am_i_host() and Steamworks.lobby_members.size() > 0:
		# Check if all Steam lobby members are also registered in NetworkManager
		can_start = _all_steam_members_network_registered()
	
	$Lobby/ButtonStartGame.disabled = not can_start

func _all_steam_members_network_registered() -> bool:
	if Steamworks.lobby_members.is_empty():
		return false
	
	var network_players = NetworkManager.get_players()
	
	# Check each Steam lobby member
	for steam_member in Steamworks.lobby_members:
		var steam_id = steam_member.get("steam_id", 0)
		var found_registered = false
		
		# Look for this Steam user in NetworkManager players
		for player_id in network_players:
			var player_data = network_players[player_id]
			if typeof(player_data) == TYPE_DICTIONARY:
				var player_steam_id = player_data.get("steam_id", 0)
				var player_status = player_data.get("status", NetworkManager.PlayerStatus.CONNECTING)
				
				if player_steam_id == steam_id and player_status == NetworkManager.PlayerStatus.REGISTERED:
					found_registered = true
					break
		
		# If any Steam member is not registered in NetworkManager, return false
		if not found_registered:
			return false
	
	return true

func _add_chat_message(message: String) -> void:
	var chat = get_node_or_null("Lobby/ChatBackground/Chat")
	if chat:
		chat.text += message + "\n"

func _refresh_lobby_list() -> void:
	for child in $LobbyList/ScrollContainer/VBoxContainer.get_children():
		child.queue_free()
	var loading_bar = ProgressBar.new()
	loading_bar.custom_minimum_size = Vector2(800, 30)
	loading_bar.indeterminate = true
	$LobbyList/ScrollContainer/VBoxContainer.add_child(loading_bar)
	if Steam:
		Steam.addRequestLobbyListStringFilter("bidding", "brawl", Steam.LOBBY_COMPARISON_EQUAL)
		Steam.addRequestLobbyListDistanceFilter(GameConfig.LOBBY_DISTANCE_FILTER)
		Steam.requestLobbyList()

#endregion

#region BUTTON CALLBACKS

func _on_button_host_pressed() -> void:
	create_lobby()

func _on_button_lobby_list_pressed() -> void:
	_refresh_lobby_list()

func _on_button_back_pressed() -> void:
	if timer_start_game.is_stopped():
		leave_lobby()
	else:
		rpc("stop_countdown")

func _on_button_start_game_pressed() -> void:
	if not Steamworks._am_i_host():
		return
	Steam.setLobbyJoinable(Steamworks.lobby_id, false)
	rpc("start_countdown")

@rpc("authority", "call_local")
func start_countdown() -> void:
	
	# Start countdown
	label_start_game.show()
	timer_start_game.start(GameConfig.GAME_START_COUNTDOWN)
	await timer_start_game.timeout
	
	# Start game
	if NetworkManager.is_server():
		NetworkManager.rpc("start_game")

@rpc("any_peer", "call_local")
func stop_countdown() -> void:
	Steam.setLobbyJoinable(Steamworks.lobby_id, true)
	timer_start_game.stop()
	label_start_game.hide()
	

#endregion

#region NETWORK CALLBACKS

func _on_players_updated(_players: Dictionary) -> void:
	if $Lobby.visible:
		_update_lobby_ui()

#endregion
