## Steamworks Integration Singleton
## Handles Steam API initialization and user data
extends Node

@export var steam_username: String

var lobby_id: int = 0
var lobby_members: Array = []

func _ready() -> void:
	initialize_steam()

func initialize_steam() -> void:
	var initialize_response: Dictionary = Steam.steamInitEx(GameConfig.STEAM_APP_ID, true)
	print("Did Steam initialize?: %s " % initialize_response)
	
	if initialize_response.get("status", 0) != 0:
		push_error("Failed to initialize Steam API")
		return
		
#region STEAM CONNECT CALLBACKS
	Steam.lobby_invite.connect(_on_invite)
	Steam.join_requested.connect(_on_lobby_join_requested)

#endregion

	steam_username = Steam.getPersonaName()
	NetworkManager.player_name = steam_username

func _am_i_host() -> bool:
	if lobby_id == 0 or not Steam:
		return false
	return Steam.getLobbyOwner(lobby_id) == Steam.getSteamID()

func join_lobby(target_lobby_id: int) -> void:
	if target_lobby_id <= 0:
		push_error("Invalid lobby ID")
		return
	
	if not Steam:
		push_error("Steam not available!")
		return
	NetworkManager.change_to_lobby()
	Steam.joinLobby(target_lobby_id)


#region CALLBACKS
func _on_lobby_join_requested(this_lobby_id: int, friend_id: int) -> void:
	join_lobby(this_lobby_id)

func _on_invite(who_invited, lobby_id, game_id):
	print(who_invited, " ", lobby_id, " ", game_id)
#endregion
