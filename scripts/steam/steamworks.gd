## Steamworks Integration Singleton
## Handles Steam API initialization and user data
extends Node

@export var steam_username: String

# Signals für Error-Handling
signal steam_error_occurred(error_message: String, error_type: String)

# Error-Puffering für frühe Errors
var _pending_errors: Array = []
var _signal_connected: bool = false

var lobby_id: int = 0
var lobby_members: Array = []
var _steam_initialized: bool = false

func _ready() -> void:
	# Initialisiere Steam nicht sofort, sondern warte auf Request
	pass

func ensure_steam_initialized() -> void:
	if not _steam_initialized:
		initialize_steam()
		_steam_initialized = true

func initialize_steam() -> void:
	var initialize_response: Dictionary = Steam.steamInitEx(GameConfig.STEAM_APP_ID, true)
	print("Did Steam initialize?: %s " % initialize_response)
	
	if initialize_response.get("status", 0) != 0:
		push_error("Failed to initialize Steam API")
		emit_signal("steam_error_occurred", "Failed to initialize Steam API, is Steam running?", "initialization")
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

# Neue Funktion zum Senden von Errors mit Puffering
func send_error(message: String, error_type: String = "general") -> void:
	if _signal_connected:
		emit_signal("steam_error_occurred", message, error_type)
	else:
		# Buffere den Error für später
		_pending_errors.append({"message": message, "type": error_type})

# Diese Funktion wird von Szenen aufgerufen, wenn sie das Signal verbinden
func connect_error_signal(callable: Callable) -> void:
	steam_error_occurred.connect(callable)
	_signal_connected = true
	
	# Sende alle gepufferten Errors
	for error in _pending_errors:
		emit_signal("steam_error_occurred", error.message, error.type)
	
	_pending_errors.clear()

func join_lobby(target_lobby_id: int) -> void:
	if target_lobby_id <= 0:
		send_error("Invalid lobby ID", "lobby_join")
		return
	
	if not Steam:
		send_error("Steam not available!", "steam_unavailable")
		return
	NetworkManager.change_to_lobby()
	Steam.joinLobby(target_lobby_id)

#region CALLBACKS
func _on_lobby_join_requested(this_lobby_id: int, _friend_id: int) -> void:
	join_lobby(this_lobby_id)

func _on_invite(who_invited, this_lobby_id, game_id):
	print(who_invited, " ", this_lobby_id, " ", game_id)
#endregion
