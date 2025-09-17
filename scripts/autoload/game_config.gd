## Game Configuration Singleton
## Contains all configurable game values for easy balancing and tweaking
extends Node

# Game Rules
const WIN_COUNT: int = 10
const MAX_PLAYERS: int = 4
const LOBBY_MEMBERS_MAX: int = 4

# Player Stats
const PLAYER_STARTING_MONEY: int = 200
const KILL_MONEY_REWARD: int = 100
const DEATH_MONEY_REWARD: int = 20

# Player Physics
const PLAYER_BASE_SPEED: float = 300.0
const PLAYER_JUMP_VELOCITY: float = -500.0
const PLAYER_BASE_HEALTH: int = 100
const PLAYER_BASE_DAMAGE: float = 10.0

# Weapon Settings
const BULLET_SPEED: float = 900.0
const BULLET_BASE_LIFETIME: float = 10.0
const SHOT_COOLDOWN_BASE: float = 0.5
const MULTISHOT_ANGLE_OFFSET: float = 15.0

# Upgrade Values
const FIRERATE_MULTIPLIER: float = 0.9  # 10% faster shooting
const HEALTH_UPGRADE_AMOUNT: int = 20
const SPEED_UPGRADE_AMOUNT: float = 50.0
const JUMP_HEIGHT_UPGRADE: float = 100.0
const BULLET_BOUNCE_AMOUNT: int = 1
const HOMING_TIME_AMOUNT: float = 0.1
const MULTIJUMP_AMOUNT: int = 1
const MULTISHOT_AMOUNT: int = 1

# UI Timers
const NEW_ROUND_TIMER: float = 3.0
const GAME_END_DELAY: float = 2.0
const SCENE_TRANSITION_DELAY: float = 0.5
const BIDDING_DESPAWN_DELAY: float = 1.0

# Audio Settings
const SHOOTER_VOLUME_DB: float = 0.0
const OTHER_PLAYERS_VOLUME_DB: float = -16.0
const OTHER_PLAYERS_PITCH_SCALE: float = 0.70

# Bidding System
const UPGRADE_SHOP_COUNT: int = 4

# Arena Settings
const DEATH_Y_THRESHOLD: float = 768.0

# Network Settings
const PACKET_READ_LIMIT: int = 32

# Steam Settings
const STEAM_APP_ID: int = 480  # Spacewar (test app)
const LOBBY_TYPE = Steam.LOBBY_TYPE_PUBLIC
const LOBBY_DISTANCE_FILTER = Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE

# Available Arena Scenes
const ARENA_SCENES: Array[String] = [
	"res://scenes/arenas/arena_2.tscn"
	# "res://scenes/arenas/arena_duck.tscn",
	# "res://scenes/arenas/arena_fortress.tscn"
]

# Error Messages
const ERROR_MESSAGES: Dictionary = {
	"version_mismatch": "Version mismatch! Server version: %s, Your version: %s",
	"connection_failed": "Connection failed",
	"server_disconnected": "Server disconnected",
	"arena_load_failed": "Failed to load arena scene: %s",
	"spawn_positions_null": "spawn_positions is null! Arena may not be loaded yet.",
	"upgrade_slot_not_found": "Upgrade slot %s not found, skipping update"
}

# Steam Lobby Join Failure Messages
const STEAM_JOIN_FAIL_MESSAGES: Dictionary = {
	Steam.CHAT_ROOM_ENTER_RESPONSE_DOESNT_EXIST: "This lobby no longer exists.",
	Steam.CHAT_ROOM_ENTER_RESPONSE_NOT_ALLOWED: "You don't have permission to join this lobby.",
	Steam.CHAT_ROOM_ENTER_RESPONSE_FULL: "The lobby is now full.",
	Steam.CHAT_ROOM_ENTER_RESPONSE_ERROR: "Uh... something unexpected happened!",
	Steam.CHAT_ROOM_ENTER_RESPONSE_BANNED: "You are banned from this lobby.",
	Steam.CHAT_ROOM_ENTER_RESPONSE_LIMITED: "You cannot join due to having a limited account.",
	Steam.CHAT_ROOM_ENTER_RESPONSE_CLAN_DISABLED: "This lobby is locked or disabled.",
	Steam.CHAT_ROOM_ENTER_RESPONSE_COMMUNITY_BAN: "This lobby is community locked.",
	Steam.CHAT_ROOM_ENTER_RESPONSE_MEMBER_BLOCKED_YOU: "A user in the lobby has blocked you from joining.",
	Steam.CHAT_ROOM_ENTER_RESPONSE_YOU_BLOCKED_MEMBER: "A user you have blocked is in the lobby."
}

## Gets a random arena scene path
func get_random_arena() -> String:
	if ARENA_SCENES.is_empty():
		push_error("No arena scenes configured!")
		return ""
	return ARENA_SCENES[randi() % ARENA_SCENES.size()]

## Gets an error message by key with optional formatting
func get_error_message(key: String, args: Array = []) -> String:
	if not ERROR_MESSAGES.has(key):
		push_error("Unknown error message key: " + key)
		return "Unknown error"
	
	var message: String = ERROR_MESSAGES[key]
	if args.is_empty():
		return message
	return message % args

## Gets Steam lobby join failure message
func get_steam_join_fail_message(response_code: int) -> String:
	return STEAM_JOIN_FAIL_MESSAGES.get(response_code, "Unknown error occurred while joining lobby.")
