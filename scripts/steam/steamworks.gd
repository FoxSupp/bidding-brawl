## Steamworks Integration Singleton
## Handles Steam API initialization and user data
extends Node

@export var steam_username: String

func _ready() -> void:
	initialize_steam()

func initialize_steam() -> void:
	var initialize_response: Dictionary = Steam.steamInitEx(GameConfig.STEAM_APP_ID, true)
	print("Did Steam initialize?: %s " % initialize_response)
	
	if initialize_response.get("status", 0) != 0:
		push_error("Failed to initialize Steam API")
		return
		
	steam_username = Steam.getPersonaName()
	NetworkManager.player_name = steam_username
