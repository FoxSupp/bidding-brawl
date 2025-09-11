extends Node

var player_stats = {}

signal player_stats_received(peer_id: int, stats: Dictionary)

func newPlayer(peer_id: int) -> void:
	if not multiplayer.is_server(): return
	player_stats[peer_id] = {
		"username": NetworkManager.get_username(peer_id),
		"money": 0,
		"wins": 0,
		"winstreak": 0,
		"losingstreak": 0,
		"upgrades": []
	}

func add_money(peer_id: int, amount: int) -> void:
	if not multiplayer.is_server(): return

	print("MONEY ADDED: ", amount)
		
	if player_stats.has(peer_id):
		player_stats[peer_id]["money"] += amount
	rpc_id(peer_id, "receive_player_stats", peer_id, player_stats[peer_id])

func win(peer_id: int) -> void:
	if not multiplayer.is_server(): return
		
	if player_stats.has(peer_id):
		player_stats[peer_id]["wins"] += 1
		player_stats[peer_id]["winstreak"] += 1
		player_stats[peer_id]["losingstreak"] = 0
		
		# Alle anderen Spieler verlieren
		for other_id in player_stats.keys():
			if other_id != peer_id:
				player_stats[other_id]["winstreak"] = 0
				player_stats[other_id]["losingstreak"] += 1

func add_upgrade(peer_id: int, upgrade_id: String) -> void:
	if not multiplayer.is_server(): return
	
	if player_stats.has(peer_id):
		player_stats[peer_id]["upgrades"].append(upgrade_id)

@rpc("any_peer", "call_local")
func get_player_stats(peer_id: int):
	if not multiplayer.is_server(): return
	var stats = player_stats[peer_id]
	rpc_id(peer_id, "receive_player_stats", peer_id, stats)

@rpc("any_peer", "call_local")
func receive_player_stats(peer_id: int, stats: Dictionary):
	emit_signal("player_stats_received", peer_id, stats)
