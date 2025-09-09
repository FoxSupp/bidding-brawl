extends Control

var player_money
var upgrade

@onready var background: Panel = $Background
@onready var label_money: Label = $Background/LabelMoney
@onready var slider_bid: HSlider = $Background/SliderBid
@onready var label_bid_amount: Label = $Background/SliderBid/LabelBidAmount
@onready var button_upgrade: Button = $ButtonUpgrade


func _ready() -> void:
	player_money = SessionManager.player_stats[multiplayer.get_unique_id()]["money"]
	print(player_money)
	_setup_ui()

func _setup_ui() -> void:
	label_money.text = "Money: " + str(player_money)
	slider_bid.max_value = player_money
	label_bid_amount.text = "Bid: " + str(int(slider_bid.value))
	slider_bid.value_changed.connect(_on_slider_value_changed)
	
	if upgrade and upgrade is WeaponEffect:
		button_upgrade.text = upgrade.upgrade_name
	else:
		button_upgrade.text = "No Upgrade"

func _on_slider_value_changed(value: float) -> void:
	label_bid_amount.text = "Bid: " + str(int(value))


func _on_button_cancel_pressed() -> void:
	background.hide()


func _on_button_submit_pressed() -> void:
	background.hide()
	print(int(slider_bid.value))


func _on_button_upgrade_pressed() -> void:
	background.show()
