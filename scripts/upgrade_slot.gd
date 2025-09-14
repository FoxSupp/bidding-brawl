extends Control

var slot_index: int
var upgrade: UpgradeBase
var bidding_manager
var player_stats: Dictionary

@onready var label_money: Label = get_tree().root.get_node("/root/BiddingMenu/Background/LabelBidMoney")
@onready var label_bid_amount: Label = $Background/VBoxContainer/BidAmountContainer/LabelBidAmount
@onready var label_highest_bidder: Label = $HighestBidderContainer/LabelHighestBidder
@onready var button_bid: Button = $ButtonBid

var slot_bids: Dictionary = {}

const BID_AMOUNT: int = 10

func _ready() -> void:
	bidding_manager = get_tree().root.get_node("/root/BiddingMenu/BiddingManager")
	bidding_manager.bids_updated.connect(_on_bids_updated)
	SessionManager.player_stats_received.connect(_on_player_stats_received)
	# Stats einmalig beim Start laden
	SessionManager.rpc_id(1, "get_player_stats", multiplayer.get_unique_id())
	await SessionManager.player_stats_received
	_update_money_ui()

func _on_button_pressed() -> void:
	if upgrade:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			if player_stats["money"] < BID_AMOUNT:
				return
			bidding_manager.rpc_id(1, "add_bid", slot_index, multiplayer.get_unique_id(), BID_AMOUNT)
		elif Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			if not slot_bids.has(multiplayer.get_unique_id()):
				return
			if slot_bids[multiplayer.get_unique_id()] <= 0:
				return
			bidding_manager.rpc_id(1, "add_bid", slot_index, multiplayer.get_unique_id(), -BID_AMOUNT)

func _on_bids_updated(index: int, bids: Dictionary) -> void:
	if index == slot_index:
		if bids.has(multiplayer.get_unique_id()):
			label_bid_amount.text = str(bids[multiplayer.get_unique_id()])
		else:
			label_bid_amount.text = "0"
		slot_bids = bids
		_update_money_ui()

func _on_player_stats_received(peer_id: int, stats: Dictionary) -> void:
	if peer_id == multiplayer.get_unique_id():
		player_stats = stats

func _update_money_ui() -> void:
	label_money.text = "Money: " + str(player_stats["money"])

@rpc("authority", "call_local")
func update_highest_bid_ui(player_name: String) -> void:
	
	label_highest_bidder.show()
	
	label_highest_bidder.text = "Highest Bidder:\n" + player_name
	button_bid.disabled = true
