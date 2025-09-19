## Lobby Configuration Panel
## UI for configuring game settings in lobby
## Only editable by host, read-only for clients
extends Panel

# UI References - SpinBoxes
@onready var win_count_spinbox: SpinBox = $VBoxContainer/ScrollContainer/ConfigContainer/GameRulesSection/WinCountContainer/WinCountSpinBox
@onready var starting_money_spinbox: SpinBox = $VBoxContainer/ScrollContainer/ConfigContainer/GameRulesSection/StartingMoneyContainer/StartingMoneySpinBox
@onready var kill_reward_spinbox: SpinBox = $VBoxContainer/ScrollContainer/ConfigContainer/GameRulesSection/KillRewardContainer/KillRewardSpinBox
@onready var death_reward_spinbox: SpinBox = $VBoxContainer/ScrollContainer/ConfigContainer/GameRulesSection/DeathRewardContainer/DeathRewardSpinBox
@onready var base_health_spinbox: SpinBox = $VBoxContainer/ScrollContainer/ConfigContainer/PlayerConfigSection/BaseHealthContainer/BaseHealthSpinBox
@onready var base_damage_spinbox: SpinBox = $VBoxContainer/ScrollContainer/ConfigContainer/PlayerConfigSection/BaseDamageContainer/BaseDamageSpinBox
@onready var health_upgrade_spinbox: SpinBox = $VBoxContainer/ScrollContainer/ConfigContainer/UpgradeSection/HealthUpgradeContainer/HealthUpgradeSpinBox
@onready var speed_upgrade_spinbox: SpinBox = $VBoxContainer/ScrollContainer/ConfigContainer/UpgradeSection/SpeedUpgradeContainer/SpeedUpgradeSpinBox
@onready var upgrade_shop_count_spinbox: SpinBox = $VBoxContainer/ScrollContainer/ConfigContainer/BiddingSection/UpgradeShopCountContainer/UpgradeShopCountSpinBox

# UI References - Sliders and Labels
@onready var shot_cooldown_slider: HSlider = $VBoxContainer/ScrollContainer/ConfigContainer/WeaponSection/ShotCooldownContainer/ShotCooldownSlider
@onready var shot_cooldown_value_label: Label = $VBoxContainer/ScrollContainer/ConfigContainer/WeaponSection/ShotCooldownContainer/ShotCooldownLabelContainer/ShotCooldownValueLabel
@onready var firerate_slider: HSlider = $VBoxContainer/ScrollContainer/ConfigContainer/UpgradeSection/FirerateContainer/FirerateSlider
@onready var firerate_value_label: Label = $VBoxContainer/ScrollContainer/ConfigContainer/UpgradeSection/FirerateContainer/FirerateLabelContainer/FirerateValueLabel
@onready var homing_time_slider: HSlider = $VBoxContainer/ScrollContainer/ConfigContainer/UpgradeSection/HomingTimeContainer/HomingTimeSlider
@onready var homing_time_value_label: Label = $VBoxContainer/ScrollContainer/ConfigContainer/UpgradeSection/HomingTimeContainer/HomingTimeLabelContainer/HomingTimeValueLabel

# Other UI References
@onready var reset_button: Button = $VBoxContainer/HeaderContainer/ResetButton

# State tracking
var is_updating_ui: bool = false
var is_host: bool = false

func _ready() -> void:
	_setup_connections()
	_update_host_status()
	_load_current_values()

func _setup_connections() -> void:
	# Connect to LobbyConfig signals
	LobbyConfig.config_updated.connect(_on_config_updated)
	LobbyConfig.config_synced.connect(_on_config_synced)
	
	# Connect to NetworkManager to track host status
	NetworkManager.players_updated.connect(_on_players_updated)

func _update_host_status() -> void:
	is_host = NetworkManager.is_server()
	_set_controls_enabled(is_host)

func _set_controls_enabled(enabled: bool) -> void:
	# Enable/disable all input controls based on host status
	win_count_spinbox.editable = enabled
	starting_money_spinbox.editable = enabled
	kill_reward_spinbox.editable = enabled
	death_reward_spinbox.editable = enabled
	base_health_spinbox.editable = enabled
	base_damage_spinbox.editable = enabled
	health_upgrade_spinbox.editable = enabled
	speed_upgrade_spinbox.editable = enabled
	upgrade_shop_count_spinbox.editable = enabled
	
	shot_cooldown_slider.editable = enabled
	firerate_slider.editable = enabled
	homing_time_slider.editable = enabled
	
	reset_button.disabled = not enabled

func _load_current_values() -> void:
	is_updating_ui = true
	
	# Load values from LobbyConfig
	win_count_spinbox.value = LobbyConfig.win_count
	starting_money_spinbox.value = LobbyConfig.starting_money
	kill_reward_spinbox.value = LobbyConfig.kill_money_reward
	death_reward_spinbox.value = LobbyConfig.death_money_reward
	base_health_spinbox.value = LobbyConfig.base_health
	base_damage_spinbox.value = LobbyConfig.base_damage
	health_upgrade_spinbox.value = LobbyConfig.health_upgrade_amount
	speed_upgrade_spinbox.value = LobbyConfig.speed_upgrade_amount
	upgrade_shop_count_spinbox.value = LobbyConfig.upgrade_shop_count
	
	# Load slider values and update labels
	shot_cooldown_slider.value = LobbyConfig.shot_cooldown
	_update_shot_cooldown_label(LobbyConfig.shot_cooldown)
	
	firerate_slider.value = LobbyConfig.firerate_multiplier
	_update_firerate_label(LobbyConfig.firerate_multiplier)
	
	homing_time_slider.value = LobbyConfig.homing_time_amount
	_update_homing_time_label(LobbyConfig.homing_time_amount)
	
	is_updating_ui = false

func _update_shot_cooldown_label(value: float) -> void:
	shot_cooldown_value_label.text = "%.2fs" % value

func _update_firerate_label(value: float) -> void:
	firerate_value_label.text = "%.2f" % value

func _update_homing_time_label(value: float) -> void:
	homing_time_value_label.text = "%.2fs" % value

# Signal handlers for UI changes
func _on_win_count_spin_box_value_changed(value: float) -> void:
	if is_updating_ui or not is_host:
		return
	LobbyConfig.set_config_value("win_count", int(value))

func _on_starting_money_spin_box_value_changed(value: float) -> void:
	if is_updating_ui or not is_host:
		return
	LobbyConfig.set_config_value("starting_money", int(value))

func _on_kill_reward_spin_box_value_changed(value: float) -> void:
	if is_updating_ui or not is_host:
		return
	LobbyConfig.set_config_value("kill_money_reward", int(value))

func _on_death_reward_spin_box_value_changed(value: float) -> void:
	if is_updating_ui or not is_host:
		return
	LobbyConfig.set_config_value("death_money_reward", int(value))

func _on_base_health_spin_box_value_changed(value: float) -> void:
	if is_updating_ui or not is_host:
		return
	LobbyConfig.set_config_value("base_health", int(value))

func _on_base_damage_spin_box_value_changed(value: float) -> void:
	if is_updating_ui or not is_host:
		return
	LobbyConfig.set_config_value("base_damage", value)

func _on_shot_cooldown_slider_value_changed(value: float) -> void:
	_update_shot_cooldown_label(value)
	if is_updating_ui or not is_host:
		return
	LobbyConfig.set_config_value("shot_cooldown", value)

func _on_firerate_slider_value_changed(value: float) -> void:
	_update_firerate_label(value)
	if is_updating_ui or not is_host:
		return
	LobbyConfig.set_config_value("firerate_multiplier", value)

func _on_health_upgrade_spin_box_value_changed(value: float) -> void:
	if is_updating_ui or not is_host:
		return
	LobbyConfig.set_config_value("health_upgrade_amount", int(value))

func _on_speed_upgrade_spin_box_value_changed(value: float) -> void:
	if is_updating_ui or not is_host:
		return
	LobbyConfig.set_config_value("speed_upgrade_amount", value)

func _on_homing_time_slider_value_changed(value: float) -> void:
	_update_homing_time_label(value)
	if is_updating_ui or not is_host:
		return
	LobbyConfig.set_config_value("homing_time_amount", value)

func _on_upgrade_shop_count_spin_box_value_changed(value: float) -> void:
	if is_updating_ui or not is_host:
		return
	LobbyConfig.set_config_value("upgrade_shop_count", int(value))

func _on_reset_button_pressed() -> void:
	if not is_host:
		return
	LobbyConfig.reset_to_defaults()

# Signal handlers for config updates
func _on_config_updated(setting_name: String, value) -> void:
	# Update individual UI element when config changes
	_update_ui_for_setting(setting_name, value)

func _on_config_synced(_config_data: Dictionary) -> void:
	# Update all UI elements when full config is synced
	_load_current_values()

func _update_ui_for_setting(setting_name: String, value) -> void:
	is_updating_ui = true
	
	match setting_name:
		"win_count":
			win_count_spinbox.value = value
		"starting_money":
			starting_money_spinbox.value = value
		"kill_money_reward":
			kill_reward_spinbox.value = value
		"death_money_reward":
			death_reward_spinbox.value = value
		"base_health":
			base_health_spinbox.value = value
		"base_damage":
			base_damage_spinbox.value = value
		"shot_cooldown":
			shot_cooldown_slider.value = value
			_update_shot_cooldown_label(value)
		"firerate_multiplier":
			firerate_slider.value = value
			_update_firerate_label(value)
		"health_upgrade_amount":
			health_upgrade_spinbox.value = value
		"speed_upgrade_amount":
			speed_upgrade_spinbox.value = value
		"homing_time_amount":
			homing_time_slider.value = value
			_update_homing_time_label(value)
		"upgrade_shop_count":
			upgrade_shop_count_spinbox.value = value
	
	is_updating_ui = false

func _on_players_updated(_players: Dictionary) -> void:
	_update_host_status()
