extends Control

const PLAYER_STAT_BLOCK = preload("res://scenes/player_stat_block.tscn")
const UPGRADE_SLOT = preload("res://scenes/upgrade_slot.tscn")
const NEW_ROUND_TIMER: float = 3.0


@export var ready_players: Array = []
"""Upgrades"""

@onready var bidding_manager: Node = $BiddingManager
@onready var button_ready: Button = $Background/ButtonReady
@onready var label_ready_players: Label = $Background/LabelReadyPlayers
@onready var player_stats: VBoxContainer = $Background/PlayerStats
@onready var upgrade_slots: HBoxContainer = $Background/UpgradeSlots
@onready var timer_start_round: Timer = $TimerStartRound
@onready var label_timer_countdown: Label = $Background/LabelTimerCountdown


func _ready() -> void:
	button_ready.pressed.connect(func(): rpc("ready_player"))
	if multiplayer.is_server():
		rpc("update_player_stats_from_server", SessionManager.player_stats)
		# Convert UpgradeBase array to Dictionary array for RPC
		var upgrade_dicts: Array[Dictionary] = []
		for upgrade in bidding_manager.available_upgrades:
			upgrade_dicts.append({
				"id": upgrade.id,
				"upgrade_id": upgrade.upgrade.id,
				"name": upgrade.upgrade.name,
				"description": upgrade.upgrade.description
			})
		rpc("update_available_upgrades", upgrade_dicts)

func _process(_delta: float) -> void:
	if not multiplayer.is_server(): return
	var all_ready = ready_players.size() >= NetworkManager.players.size()
	if all_ready:
		rpc("update_all_ready_ui", timer_start_round.time_left)
		if timer_start_round.is_stopped():
			update_highest_bid_display()
			timer_start_round.start(NEW_ROUND_TIMER)
			timer_start_round.timeout.connect(func(): NetworkManager.rpc("start_game"))
	else:
		rpc("update_waiting_ui", ready_players.size(), NetworkManager.players.size())

func update_highest_bid_display():
	"""Updates the UI to show the highest bidder for each upgrade slot"""
	for upgrade in bidding_manager.available_upgrades:
		var slot = upgrade_slots.get_node_or_null(str(upgrade.id))
		var highest_bidder_id = bidding_manager.get_highest_bid(upgrade.id)
		if highest_bidder_id != 0:
			var highest_bid_player = SessionManager.player_stats[highest_bidder_id]
			slot.rpc("update_highest_bid_ui", highest_bid_player["username"])
			SessionManager.add_upgrade(highest_bidder_id, upgrade.upgrade.id)
		else:
			slot.rpc("update_highest_bid_ui", "None")

@rpc("any_peer", "call_local")
func ready_player():
	if multiplayer.is_server():
		ready_players.append(multiplayer.get_remote_sender_id())

@rpc("authority", "call_local")
func update_waiting_ui(ready_count: int, total_count: int):
	label_ready_players.text = "Waiting for Players to Ready up \n" + str(ready_count) + "/" + str(total_count)
	label_timer_countdown.hide()

@rpc("authority", "call_local") 
func update_all_ready_ui(time_left: float):
	label_ready_players.text = "All Players Ready, Game Starting Soon"
	label_timer_countdown.show()
	label_timer_countdown.text = "Game Starting in " + str("%.1f" % time_left)

@rpc("authority", "call_local")
func update_player_stats_from_server(stats_data: Dictionary):
	for child in player_stats.get_children(): child.queue_free()
	for peer_id in stats_data:
		var data = stats_data[peer_id]
		if typeof(data) == TYPE_DICTIONARY:
			var block = PLAYER_STAT_BLOCK.instantiate()
			player_stats.add_child(block)
			block.get_node("Panel/LabelUsername").text = str(data["username"])
			block.get_node("Panel/LabelMoney").text = "Money: " + str(data["money"])
			block.get_node("Panel/LabelWins").text = "Wins: " + str(data["wins"])

@rpc("authority", "call_local")
func update_available_upgrades(upgrade_data: Array[Dictionary]):
	# Clear previous upgrade slots
	for c in upgrade_slots.get_children():
		c.queue_free()
	
	for upgrade in upgrade_data:
		var slot = UPGRADE_SLOT.instantiate()
		slot.name = str(upgrade.id)
		upgrade_slots.add_child(slot, true)
		slot.slot_index = upgrade.id
		slot.upgrade = UpgradeManager.get_upgrade_by_id(upgrade.upgrade_id)
		
		# Set name and description
		if slot.has_node("LabelName"):
			var label_name = slot.get_node("LabelName") as Label
			label_name.text = upgrade.name
			label_name.tooltip_text = upgrade.description
		
		# Set description label if exists
		if slot.has_node("LabelDescription"):
			var label_desc = slot.get_node("LabelDescription") as Label
			label_desc.text = upgrade.description
