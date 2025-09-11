extends Node

var available_upgrades = []

var upgrades_in_shop: int = 4

func _ready() -> void:
	
	if not multiplayer.is_server(): return

	for i in range(upgrades_in_shop):
		available_upgrades.append(
			{
				"upgrade_id": i,
				"upgrade_name": "Upgrade " + str(i), # TODO: Upgrade Name from Upgrage
				"upgrade": {}, # TODO: Upgrade from Upgrade
				"bids":{} #TODO Add bids {peer_id: bid_amount}
			}
		)
