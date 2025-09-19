## Lobby Configuration Singleton
## Manages configurable game values that can be modified by lobby host
## Values are synced across all clients and persist between sessions
extends Node

# Signals for UI updates
signal config_updated(setting_name: String, value)
signal config_synced(config_data: Dictionary)

# Configurable Game Rules
var win_count: int = GameConfig.WIN_COUNT
var starting_money: int = GameConfig.PLAYER_STARTING_MONEY
var kill_money_reward: int = GameConfig.KILL_MONEY_REWARD
var death_money_reward: int = GameConfig.DEATH_MONEY_REWARD

# Configurable Player Stats
var base_health: int = GameConfig.PLAYER_BASE_HEALTH
var base_damage: float = GameConfig.PLAYER_BASE_DAMAGE

# Configurable Weapon Settings
var shot_cooldown: float = GameConfig.SHOT_COOLDOWN_BASE

# Configurable Upgrade Values
var firerate_multiplier: float = GameConfig.FIRERATE_MULTIPLIER
var health_upgrade_amount: int = GameConfig.HEALTH_UPGRADE_AMOUNT
var speed_upgrade_amount: float = GameConfig.SPEED_UPGRADE_AMOUNT
var homing_time_amount: float = GameConfig.HOMING_TIME_AMOUNT

# Configurable Bidding Settings
var upgrade_shop_count: int = GameConfig.UPGRADE_SHOP_COUNT

# Configuration limits for validation
const CONFIG_LIMITS = {
	"win_count": {"min": 1, "max": 50, "step": 1},
	"starting_money": {"min": 50, "max": 1000, "step": 10},
	"kill_money_reward": {"min": 10, "max": 500, "step": 10},
	"death_money_reward": {"min": 0, "max": 100, "step": 5},
	"base_health": {"min": 25, "max": 300, "step": 5},
	"base_damage": {"min": 5.0, "max": 50.0, "step": 1.0},
	"shot_cooldown": {"min": 0.1, "max": 2.0, "step": 0.05},
	"firerate_multiplier": {"min": 0.5, "max": 1.0, "step": 0.05},
	"health_upgrade_amount": {"min": 5, "max": 50, "step": 5},
	"speed_upgrade_amount": {"min": 10.0, "max": 200.0, "step": 10.0},
	"homing_time_amount": {"min": 0.05, "max": 1.0, "step": 0.05},
	"upgrade_shop_count": {"min": 2, "max": 8, "step": 1}
}

# Save file path
const SAVE_PATH = "user://lobby_config.save"

func _ready() -> void:
	load_config()

## Set a configuration value with validation
func set_config_value(setting_name: String, value) -> void:
	if not CONFIG_LIMITS.has(setting_name):
		push_error("Unknown config setting: " + setting_name)
		return
	
	var limits = CONFIG_LIMITS[setting_name]
	var clamped_value = clamp(value, limits.min, limits.max)
	
	# Set the actual property
	match setting_name:
		"win_count":
			win_count = int(clamped_value)
		"starting_money":
			starting_money = int(clamped_value)
		"kill_money_reward":
			kill_money_reward = int(clamped_value)
		"death_money_reward":
			death_money_reward = int(clamped_value)
		"base_health":
			base_health = int(clamped_value)
		"base_damage":
			base_damage = float(clamped_value)
		"shot_cooldown":
			shot_cooldown = float(clamped_value)
		"firerate_multiplier":
			firerate_multiplier = float(clamped_value)
		"health_upgrade_amount":
			health_upgrade_amount = int(clamped_value)
		"speed_upgrade_amount":
			speed_upgrade_amount = float(clamped_value)
		"homing_time_amount":
			homing_time_amount = float(clamped_value)
		"upgrade_shop_count":
			upgrade_shop_count = int(clamped_value)
	
	emit_signal("config_updated", setting_name, clamped_value)
	
	# Sync to all clients if we're the server
	if NetworkManager.is_server():
		NetworkManager.rpc("sync_lobby_config", get_config_data())
	
	# Save immediately
	save_config()

## Get a configuration value
func get_config_value(setting_name: String):
	match setting_name:
		"win_count":
			return win_count
		"starting_money":
			return starting_money
		"kill_money_reward":
			return kill_money_reward
		"death_money_reward":
			return death_money_reward
		"base_health":
			return base_health
		"base_damage":
			return base_damage
		"shot_cooldown":
			return shot_cooldown
		"firerate_multiplier":
			return firerate_multiplier
		"health_upgrade_amount":
			return health_upgrade_amount
		"speed_upgrade_amount":
			return speed_upgrade_amount
		"homing_time_amount":
			return homing_time_amount
		"upgrade_shop_count":
			return upgrade_shop_count
		_:
			push_error("Unknown config setting: " + setting_name)
			return null

## Get all configuration data as dictionary
func get_config_data() -> Dictionary:
	return {
		"win_count": win_count,
		"starting_money": starting_money,
		"kill_money_reward": kill_money_reward,
		"death_money_reward": death_money_reward,
		"base_health": base_health,
		"base_damage": base_damage,
		"shot_cooldown": shot_cooldown,
		"firerate_multiplier": firerate_multiplier,
		"health_upgrade_amount": health_upgrade_amount,
		"speed_upgrade_amount": speed_upgrade_amount,
		"homing_time_amount": homing_time_amount,
		"upgrade_shop_count": upgrade_shop_count
	}

## Apply configuration data from dictionary
func apply_config_data(config_data: Dictionary) -> void:
	for setting_name in config_data:
		if CONFIG_LIMITS.has(setting_name):
			var value = config_data[setting_name]
			var limits = CONFIG_LIMITS[setting_name]
			var clamped_value = clamp(value, limits.min, limits.max)
			
			# Set without triggering RPC (to avoid infinite loops)
			match setting_name:
				"win_count":
					win_count = int(clamped_value)
				"starting_money":
					starting_money = int(clamped_value)
				"kill_money_reward":
					kill_money_reward = int(clamped_value)
				"death_money_reward":
					death_money_reward = int(clamped_value)
				"base_health":
					base_health = int(clamped_value)
				"base_damage":
					base_damage = float(clamped_value)
				"shot_cooldown":
					shot_cooldown = float(clamped_value)
				"firerate_multiplier":
					firerate_multiplier = float(clamped_value)
				"health_upgrade_amount":
					health_upgrade_amount = int(clamped_value)
				"speed_upgrade_amount":
					speed_upgrade_amount = float(clamped_value)
				"homing_time_amount":
					homing_time_amount = float(clamped_value)
				"upgrade_shop_count":
					upgrade_shop_count = int(clamped_value)
	
	emit_signal("config_synced", config_data)

## Reset all values to GameConfig defaults
func reset_to_defaults() -> void:
	win_count = GameConfig.WIN_COUNT
	starting_money = GameConfig.PLAYER_STARTING_MONEY
	kill_money_reward = GameConfig.KILL_MONEY_REWARD
	death_money_reward = GameConfig.DEATH_MONEY_REWARD
	base_health = GameConfig.PLAYER_BASE_HEALTH
	base_damage = GameConfig.PLAYER_BASE_DAMAGE
	shot_cooldown = GameConfig.SHOT_COOLDOWN_BASE
	firerate_multiplier = GameConfig.FIRERATE_MULTIPLIER
	health_upgrade_amount = GameConfig.HEALTH_UPGRADE_AMOUNT
	speed_upgrade_amount = GameConfig.SPEED_UPGRADE_AMOUNT
	homing_time_amount = GameConfig.HOMING_TIME_AMOUNT
	upgrade_shop_count = GameConfig.UPGRADE_SHOP_COUNT
	
	if NetworkManager.is_server():
		NetworkManager.rpc("sync_lobby_config", get_config_data())
	
	save_config()
	emit_signal("config_synced", get_config_data())

## Save configuration to file
func save_config() -> void:
	var save_file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if save_file == null:
		push_error("Failed to open save file for writing")
		return
	
	var config_data = get_config_data()
	save_file.store_string(JSON.stringify(config_data))
	save_file.close()

## Load configuration from file
func load_config() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	
	var save_file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if save_file == null:
		push_error("Failed to open save file for reading")
		return
	
	var json_string = save_file.get_as_text()
	save_file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		push_error("Error parsing config save file")
		return
	
	var config_data = json.data
	if typeof(config_data) == TYPE_DICTIONARY:
		apply_config_data(config_data)

## Get configuration limits for a setting
func get_config_limits(setting_name: String) -> Dictionary:
	return CONFIG_LIMITS.get(setting_name, {})
