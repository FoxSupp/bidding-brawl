extends Control

var slot_index: int
var upgrade: UpgradeBase
var bidding_manager
var player_stats: Dictionary

@onready var label_money: Label
@onready var label_bid_amount: Label = $Background/VBoxContainer/BidAmountContainer/LabelBidAmount
@onready var label_highest_bidder: Label = $HighestBidderContainer/LabelHighestBidder
@onready var highest_bidder_container: Panel = $HighestBidderContainer
@onready var button_bid: Button = $ButtonBid

var slot_bids: Dictionary = {}

const BID_AMOUNT: int = 10

func _ready() -> void:
	# Wait for the node tree to be fully built
	await get_tree().process_frame
	_setup_node_references()
	
	SessionManager.player_stats_received.connect(_on_player_stats_received)
	# Stats einmalig beim Start laden
	SessionManager.rpc_id(1, "get_player_stats", multiplayer.get_unique_id())
	await SessionManager.player_stats_received
	_update_money_ui()

func _setup_node_references() -> void:
	# Safely get references to nodes that might not exist yet
	var bidding_menu = get_tree().get_first_node_in_group("bidding_menu")
	if not bidding_menu:
		bidding_menu = get_tree().root.get_node_or_null("BiddingMenu")
	
	if bidding_menu:
		bidding_manager = bidding_menu.get_node_or_null("BiddingManager")
		label_money = bidding_menu.get_node_or_null("Background/LabelBidMoney")
		
		if bidding_manager and bidding_manager.has_signal("bids_updated"):
			bidding_manager.bids_updated.connect(_on_bids_updated)
	else:
		# Fallback: try to find nodes by different methods
		bidding_manager = get_node_or_null("../../BiddingManager")
		label_money = get_node_or_null("../../Background/LabelBidMoney")
		
		if bidding_manager and bidding_manager.has_signal("bids_updated"):
			bidding_manager.bids_updated.connect(_on_bids_updated)
	
	# If still no references found, retry after another frame (max 10 retries)
	if not bidding_manager or not label_money:
		if not has_meta("retry_count"):
			set_meta("retry_count", 0)
		var retry_count = get_meta("retry_count")
		if retry_count < 10:
			set_meta("retry_count", retry_count + 1)
			call_deferred("_setup_node_references")
		else:
			print("ERROR: Could not find bidding_manager or label_money after 10 retries")

func _on_button_pressed() -> void:
	if upgrade and bidding_manager:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			if not player_stats.has("money") or player_stats["money"] < BID_AMOUNT:
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
	if label_money and player_stats.has("money"):
		label_money.text = "Money: " + str(player_stats["money"])

@rpc("authority", "call_local")
func update_highest_bid_ui(player_name: String) -> void:
	
	highest_bidder_container.show()
	
	label_highest_bidder.text = "Highest Bidder:\n" + player_name
	button_bid.disabled = true
