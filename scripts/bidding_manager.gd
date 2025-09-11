extends Node

signal bids_updated(index: int, bids: Dictionary)

var available_upgrades: Array = []

var count_upgrades_in_shop: int = 4

func _ready() -> void:
	
	if not multiplayer.is_server(): return

	for i in range(count_upgrades_in_shop):
		available_upgrades.append({
			"id": i,
			"upgrade" : UpgradeManager.get_random_upgrade(),
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
func add_bid(index: int, peer_id: int, amount: int):
	if not multiplayer.is_server(): return

	if available_upgrades[index]["bids"].has(peer_id):
		if available_upgrades[index]["bids"][peer_id] + amount < 0:
			return
		available_upgrades[index]["bids"][peer_id] += amount
	else:
		if amount < 0:
			return
		available_upgrades[index]["bids"][peer_id] = amount

	SessionManager.add_money(peer_id, -amount)


	# Emit signal locally on server and send to all clients
	rpc("emit_bids_updated", index, available_upgrades[index]["bids"])

@rpc("authority", "call_local")
func emit_bids_updated(index: int, bids: Dictionary):
	emit_signal("bids_updated", index, bids)
