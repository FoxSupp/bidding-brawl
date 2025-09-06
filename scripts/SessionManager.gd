extends Node


var player_stats = {}

@rpc("authority", "call_local")
func sync_player_stats(stats: Dictionary) -> void:
	player_stats = stats

func newPlayer(peer_id: int) -> void:
	player_stats[peer_id] = {
		"username": NetworkManager.get_username(peer_id),
		"money": 0,
		"wins": 0,
		"winstreak": 0,
		"losingstreak": 0
	}

func addMoney(peer_id: int, amount: int) -> void:
	player_stats[peer_id]["money"] += amount

func win(peer_id: int) -> void:
	player_stats[peer_id]["wins"] += 1
	player_stats[peer_id]["winstreak"] += 1
	player_stats[peer_id]["losingstreak"] = 0
	for other_id in player_stats.keys():
		if other_id != peer_id:
			player_stats[other_id]["winstreak"] = 0
			player_stats[other_id]["losingstreak"] += 1
