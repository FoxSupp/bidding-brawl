extends Node

@export var steam_username: String

func _ready() -> void:
	initialize_steam()

func initialize_steam() -> void:
	var initialize_response: Dictionary = Steam.steamInitEx(480, true)
	print("Did Steam initialize?: %s " % initialize_response)
	steam_username = Steam.getPersonaName()
	NetworkManager.player_name = steam_username
