extends Control

var player_money: int = 0
var upgrade: WeaponEffect = null

@onready var background: Panel = $Background
@onready var label_money: Label = $Background/LabelMoney
@onready var slider_bid: HSlider = $Background/SliderBid
@onready var label_bid_amount: Label = $Background/SliderBid/LabelBidAmount
@onready var button_upgrade: Button = $ButtonUpgrade

func _ready() -> void:
	# Safe money retrieval
	var player_id = multiplayer.get_unique_id()
	if SessionManager.player_stats.has(player_id) and SessionManager.player_stats[player_id].has("money"):
		player_money = SessionManager.player_stats[player_id]["money"]
	else:
		player_money = 0
		print("Warning: Could not get player money for ID: ", player_id)
	
	# Wait for next frame to ensure all @onready vars are initialized
	call_deferred("_setup_ui")

func _setup_ui() -> void:
	label_money.text = "Money: " + str(player_money)
	slider_bid.max_value = max(1, player_money)  # Ensure minimum value of 1
	label_bid_amount.text = "Bid: " + str(int(slider_bid.value))
	slider_bid.value_changed.connect(_on_slider_value_changed)
	
	# Safe upgrade name retrieval
	_update_upgrade_display()

func set_upgrade(new_upgrade: WeaponEffect) -> void:
	upgrade = new_upgrade
	# Wait for next frame to ensure UI is ready
	call_deferred("_update_upgrade_display")

func _update_upgrade_display() -> void:		
	if upgrade != null and is_instance_valid(upgrade) and upgrade.has_method("get") and upgrade.get("upgrade_name") != null:
		button_upgrade.text = str(upgrade.upgrade_name)
	else:
		button_upgrade.text = "No Upgrade"
		print("Warning: Invalid upgrade object")

func _on_slider_value_changed(value: float) -> void:
	label_bid_amount.text = "Bid: " + str(int(value))



func _on_button_cancel_pressed() -> void:
	background.hide()

func _on_button_submit_pressed() -> void:
	var player_id = multiplayer.get_unique_id()
	if player_money >= int(slider_bid.value):
		SessionManager.rpc_id(1, "addMoney", player_id, -int(slider_bid.value))
	background.hide()

func _on_button_upgrade_pressed() -> void:
	background.show()
