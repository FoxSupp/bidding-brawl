## Session Manager Singleton
## Manages player statistics, money, wins, and upgrades throughout the game session
extends Node

# Player data storage
var player_stats: Dictionary = {}
var winner: Dictionary = {}

# Signals
signal player_stats_received(peer_id: int, stats: Dictionary)

func newPlayer(peer_id: int) -> void:
	if not multiplayer.is_server(): 
		return
		
	player_stats[peer_id] = {
		"username": NetworkManager.get_username(peer_id),
		"money": GameConfig.get_starting_money(),
		"kills": 0,
		"wins": 0,
		"winstreak": 0,
		"losingstreak": 0,
		"upgrades": []
	}

func add_money(peer_id: int, amount: int) -> void:
	if not multiplayer.is_server(): 
		return

	if not player_stats.has(peer_id):
		push_error("Attempted to add money to non-existent player: " + str(peer_id))
		return
		
	player_stats[peer_id]["money"] += amount
	rpc_id(peer_id, "receive_player_stats", peer_id, player_stats[peer_id])

func add_kill(peer_id: int) -> void:
	if not multiplayer.is_server(): 
		return
		
	if not player_stats.has(peer_id):
		push_error("Attempted to add kill to non-existent player: " + str(peer_id))
		return
		
	player_stats[peer_id]["kills"] += 1

func win(peer_id: int) -> void:
	if not multiplayer.is_server(): 
		return
		
	if not player_stats.has(peer_id):
		push_error("Attempted to mark win for non-existent player: " + str(peer_id))
		return
		
	# Update winner stats
	player_stats[peer_id]["wins"] += 1
	player_stats[peer_id]["winstreak"] += 1
	player_stats[peer_id]["losingstreak"] = 0
	
	# Update all other players as losers
	for other_id in player_stats.keys():
		if other_id != peer_id:
			player_stats[other_id]["winstreak"] = 0
			player_stats[other_id]["losingstreak"] += 1

func add_upgrade(peer_id: int, upgrade_id: String) -> void:
	if not multiplayer.is_server(): 
		return
	
	if not player_stats.has(peer_id):
		push_error("Attempted to add upgrade to non-existent player: " + str(peer_id))
		return
		
	player_stats[peer_id]["upgrades"].append(upgrade_id)

func clear_session() -> void:
	player_stats.clear()
	winner = {}

## Get player money safely
func get_player_money(peer_id: int) -> int:
	if not player_stats.has(peer_id):
		return 0
	return player_stats[peer_id].get("money", 0)

## Check if player has enough money for a purchase
func can_afford(peer_id: int, cost: int) -> bool:
	return get_player_money(peer_id) >= cost

## Get player statistics for UI display
func get_player_display_stats(peer_id: int) -> Dictionary:
	if not player_stats.has(peer_id):
		return {}
	
	var stats = player_stats[peer_id]
	return {
		"username": stats.get("username", "Unknown"),
		"money": stats.get("money", 0),
		"kills": stats.get("kills", 0),
		"wins": stats.get("wins", 0),
		"upgrades": stats.get("upgrades", []).size()
	}

## Check if a player exists in the session
func has_player(peer_id: int) -> bool:
	return player_stats.has(peer_id)



@rpc("any_peer", "call_local")
func get_player_stats(peer_id: int) -> void:
	if not multiplayer.is_server(): 
		return
		
	if not player_stats.has(peer_id):
		push_error("Attempted to get stats for non-existent player: " + str(peer_id))
		return
		
	var stats = player_stats[peer_id]
	rpc_id(peer_id, "receive_player_stats", peer_id, stats)

@rpc("any_peer", "call_local")
func receive_player_stats(peer_id: int, stats: Dictionary) -> void:
	emit_signal("player_stats_received", peer_id, stats)
