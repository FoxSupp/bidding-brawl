extends Control

const PACKET_READ_LIMIT: int = 32

signal lobby_updated
signal player_joined(player_name: String)
signal player_left(player_name: String)

const PLAYER_SLOT_SCENE = preload("res://scenes/menu/player_slot.tscn")

var lobby_data
var lobby_id: int = 0
var lobby_members: Array = []
var lobby_members_max: int = 4
var lobby_vote_kick: bool = false
#var steam_id: int = 0
var steam_username: String = ""

func _ready() -> void:
	lobby_updated.connect(_update_lobby_ui)
	
	player_joined.connect(_on_player_joined)
	player_left.connect(_on_player_left)
	
	NetworkManager.players_updated.connect(_on_players_updated)
	
	Steam.join_requested.connect(_on_lobby_join_requested)
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_match_list.connect(_on_lobby_match_list)
	Steam.lobby_joined.connect(_on_lobby_joined)
	Steam.lobby_chat_update.connect(_on_lobby_chat_update)
	#Steam.lobby_data_update.connect(_on_lobby_data_update)
	#Steam.lobby_invite.connect(_on_lobby_invite)
	#Steam.lobby_message.connect(_on_lobby_message)
	#Steam.persona_state_change.connect(_on_persona_change)
	
	check_command_line()

func _on_players_updated(_players: Dictionary) -> void:
	# Update the lobby UI when player data changes
	if $Lobby.visible:
		_update_lobby_ui()

func check_command_line() -> void:
	var these_arguments: Array = OS.get_cmdline_args()
	if these_arguments.size() > 0:
		if these_arguments[0] == "+connect_lobby":
			if int(these_arguments[1]) > 0:
				print("Command line lobby ID: %s" % these_arguments[1])
				#join_lobby(int(these_arguments[1]))

func create_lobby() -> void:
	if lobby_id == 0:
		Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, lobby_members_max)

func join_lobby(this_lobby_id: int) -> void:
	Steam.joinLobby(this_lobby_id)

func get_lobby_members() -> void:
	lobby_members.clear()
	
	var num_of_members: int = Steam.getNumLobbyMembers(lobby_id)
	
	for this_member in range(0, num_of_members):
		var member_steam_id: int = Steam.getLobbyMemberByIndex(lobby_id, this_member)
		var member_steam_name: String = Steam.getFriendPersonaName(member_steam_id)
		lobby_members.append({"steam_id": member_steam_id, "steam_name": member_steam_name})
	
func _on_lobby_created(connect: int, this_lobby_id: int) -> void:
	if connect == 1:
		lobby_id = this_lobby_id
		print("Created a lobby: %s" % lobby_id)
		
		Steam.setLobbyJoinable(lobby_id, true)
		Steam.setLobbyData(lobby_id, "name", Steam.getPersonaName() + "'s Lobby")
		Steam.setLobbyData(lobby_id, "bidding", "brawl")

		var set_relay: bool = Steam.allowP2PPacketRelay(true)
		
		#emit_signal("lobby_updated")
		NetworkManager.host()

func _on_lobby_joined(this_lobby_id: int, _permission: int, _locked: bool, response: int) -> void:
	if response == Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		lobby_id = this_lobby_id
		if Steam.getLobbyOwner(lobby_id) != Steam.getSteamID():
			NetworkManager.join_lobby(lobby_id)
		emit_signal("lobby_updated")
	else:
		# Get the failure reason
		var fail_reason: String

		match response:
			Steam.CHAT_ROOM_ENTER_RESPONSE_DOESNT_EXIST: fail_reason = "This lobby no longer exists."
			Steam.CHAT_ROOM_ENTER_RESPONSE_NOT_ALLOWED: fail_reason = "You don't have permission to join this lobby."
			Steam.CHAT_ROOM_ENTER_RESPONSE_FULL: fail_reason = "The lobby is now full."
			Steam.CHAT_ROOM_ENTER_RESPONSE_ERROR: fail_reason = "Uh... something unexpected happened!"
			Steam.CHAT_ROOM_ENTER_RESPONSE_BANNED: fail_reason = "You are banned from this lobby."
			Steam.CHAT_ROOM_ENTER_RESPONSE_LIMITED: fail_reason = "You cannot join due to having a limited account."
			Steam.CHAT_ROOM_ENTER_RESPONSE_CLAN_DISABLED: fail_reason = "This lobby is locked or disabled."
			Steam.CHAT_ROOM_ENTER_RESPONSE_COMMUNITY_BAN: fail_reason = "This lobby is community locked."
			Steam.CHAT_ROOM_ENTER_RESPONSE_MEMBER_BLOCKED_YOU: fail_reason = "A user in the lobby has blocked you from joining."
			Steam.CHAT_ROOM_ENTER_RESPONSE_YOU_BLOCKED_MEMBER: fail_reason = "A user you have blocked is in the lobby."

		print("Failed to join this chat room: %s" % fail_reason)
		_on_button_lobby_list_pressed()

""" Create Lobby List Buttons """
func _on_lobby_match_list(these_lobbies: Array) -> void:
	for c in $LobbyList/ScrollContainer/VBoxContainer.get_children():
		c.queue_free()
	for this_lobby in these_lobbies:
		var lobby_name: String = Steam.getLobbyData(this_lobby, "name")
		var bidding_brawl: String = Steam.getLobbyData(this_lobby, "bidding")
		
		if bidding_brawl != "brawl":
			continue
		
		var lobby_num_members: int = Steam.getNumLobbyMembers(this_lobby)
		# Create a button for the lobby
		var lobby_button: Button = Button.new()
		lobby_button.set_text("%s currently %s of 4 Players" % [lobby_name, lobby_num_members])
		lobby_button.set_size(Vector2(800, 50))
		lobby_button.set_name("lobby_%s" % this_lobby)
		lobby_button.connect("pressed", Callable(self, "join_lobby").bind(this_lobby))
		
		$LobbyList/ScrollContainer/VBoxContainer.add_child(lobby_button)

func _on_lobby_join_requested(this_lobby_id: int, friend_id: int) -> void:
	var owner_name: String = Steam.getFriendPersonaName(friend_id)
	join_lobby(this_lobby_id)

func _on_lobby_chat_update(this_lobby_id: int, change_id: int, making_change_id: int, chat_state: int) -> void:
	emit_signal("lobby_updated")
	
	match chat_state:
		Steam.CHAT_MEMBER_STATE_CHANGE_ENTERED:
			emit_signal("player_joined", Steam.getFriendPersonaName(change_id))
		Steam.CHAT_MEMBER_STATE_CHANGE_LEFT:
			emit_signal("player_left", Steam.getFriendPersonaName(change_id))
	print(Steam.getFriendPersonaName(change_id))

func _update_lobby_ui() -> void:
	get_lobby_members()
	_update_start_button()
	$LobbyList.hide()
	$Lobby.show()
	if lobby_id != 0:
		for c in $Lobby/ContainerPlayers.get_children():
			c.queue_free()
		
		# Display Steam lobby members first (these show as connecting)
		for member in lobby_members:
			var player_slot = PLAYER_SLOT_SCENE.instantiate()
			$Lobby/ContainerPlayers.add_child(player_slot)
			
			# Check if this Steam user is already registered in NetworkManager
			var steam_id = member.steam_id
			var username = member.steam_name
			var status = NetworkManager.PlayerStatus.CONNECTING
			
			# Look for this steam user in NetworkManager players by steam_id
			for network_id in NetworkManager.players:
				var player_data = NetworkManager.players[network_id]
				var player_steam_id = player_data.get("steam_id", 0)
				
				# Match by Steam ID (more reliable than username)
				if player_steam_id == steam_id and player_steam_id != 0:
					status = player_data.get("status", NetworkManager.PlayerStatus.CONNECTING)
					username = player_data.get("username", member.steam_name)
					break
			
			# Call deferred to ensure the node is ready
			player_slot.call_deferred("set_player_data", username, status)

func _update_start_button() -> void:
	if NetworkManager.is_server():
		# Only enable start button if all Steam lobby members are fully registered
		var all_steam_members_registered = true
		
		# Check if every Steam lobby member has a corresponding registered NetworkManager player
		for member in lobby_members:
			var steam_id = member.steam_id
			var member_registered = false
			
			# Look for this steam user in NetworkManager players
			for network_id in NetworkManager.players:
				var player_data = NetworkManager.players[network_id]
				var player_steam_id = player_data.get("steam_id", 0)
				var player_status = player_data.get("status", NetworkManager.PlayerStatus.CONNECTING)
				
				# Check if this Steam member is registered in NetworkManager
				if player_steam_id == steam_id and player_steam_id != 0 and player_status == NetworkManager.PlayerStatus.REGISTERED:
					member_registered = true
					break
			
			if not member_registered:
				all_steam_members_registered = false
				break
		
		# Also need at least one player
		var has_players = lobby_members.size() > 0
		
		$Lobby/ButtonStartGame.disabled = not (all_steam_members_registered and has_players)
	else:
		$Lobby/ButtonStartGame.disabled = true

func _on_player_joined(player_name: String) -> void:
	$Lobby/ChatBackground/Chat.text += "%s joined the Game\n-------------------------------" % player_name

func _on_player_left(player_name: String) -> void:
	$Lobby/ChatBackground/Chat.text += "%s left the Game\n-------------------------------" % player_name

func _on_button_host_pressed() -> void:
	create_lobby()

func _on_button_lobby_list_pressed() -> void:
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)
	Steam.requestLobbyList()

func _on_button_start_game_pressed() -> void:
	if NetworkManager.is_server():
		NetworkManager.rpc("start_game")
