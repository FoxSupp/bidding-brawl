## Bidding Manager
## Handles upgrade auctions and bid management for multiplayer sessions
extends Node

# Signals
signal bids_updated(index: int, bids: Dictionary)

# Bidding data
var available_upgrades: Array = []

func _ready() -> void:
	if not multiplayer.is_server(): 
		return

	# Initialize upgrade shop with random upgrades
	for i in range(GameConfig.get_upgrade_shop_count()):
		available_upgrades.append({
			"id": i,
			"upgrade": UpgradeManager.get_random_upgrade(),
			"bids": {}
		})

func get_highest_bid(index: int) -> int:
	var highest_bid = 0
	var winner_id = 0
	for bid in available_upgrades[index]["bids"].keys():
		var competing_bid = int(available_upgrades[index]["bids"][bid])
		if competing_bid > highest_bid:
			highest_bid = competing_bid
			winner_id = bid
	return winner_id

@rpc("any_peer", "call_local")
func add_bid(index: int, peer_id: int, amount: int) -> void:
	if not multiplayer.is_server(): 
		return

	# Validate upgrade index
	if index < 0 or index >= available_upgrades.size():
		push_error("Invalid upgrade index: " + str(index))
		return

	# Handle existing bid adjustment
	if available_upgrades[index]["bids"].has(peer_id):
		if available_upgrades[index]["bids"][peer_id] + amount < 0:
			return  # Can't bid negative amounts
		available_upgrades[index]["bids"][peer_id] += amount
	else:
		if amount < 0:
			return  # First bid can't be negative
		available_upgrades[index]["bids"][peer_id] = amount

	# Deduct money from player
	SessionManager.add_money(peer_id, -amount)

	# Broadcast bid update to all clients
	rpc("emit_bids_updated", index, available_upgrades[index]["bids"])

@rpc("authority", "call_local")
func emit_bids_updated(index: int, bids: Dictionary) -> void:
	emit_signal("bids_updated", index, bids)
