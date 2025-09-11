extends Node

signal player_stats_updated(new_stats: Dictionary)

var player_stats = {}

# Server-Only Funktionen
@rpc("authority", "call_local")
func newPlayer(peer_id: int) -> void:
	if not multiplayer.is_server(): return
	player_stats[peer_id] = {
		"username": NetworkManager.get_username(peer_id),
		"money": 0,
		"wins": 0,
		"winstreak": 0,
		"losingstreak": 0,
	}
	rpc("_sync_players", player_stats)


@rpc("any_peer", "call_local")
func addMoney(peer_id: int, amount: int) -> void:
	if not multiplayer.is_server(): return
		
	if player_stats.has(peer_id):
		player_stats[peer_id]["money"] += amount
	
	rpc("_sync_players", player_stats)

@rpc("authority", "call_local")
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
	rpc("_sync_players", player_stats)
	
@rpc("authority", "call_local")
func _sync_players(new_stats: Dictionary):
	player_stats = new_stats.duplicate(true)
	emit_signal("player_stats_updated", new_stats)
