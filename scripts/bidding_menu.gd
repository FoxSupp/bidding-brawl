extends Control

const PLAYER_STAT_BLOCK = preload("res://scenes/player_stat_block.tscn")
const NEW_ROUND_TIMER: float = 3.0


@export var ready_players: Array = []
@onready var button_ready: Button = $Background/ButtonReady
@onready var label_ready_players: Label = $Background/LabelReadyPlayers
@onready var player_stats: VBoxContainer = $Background/PlayerStats
@onready var timer_start_round: Timer = $TimerStartRound
@onready var label_timer_countdown: Label = $Background/LabelTimerCountdown


func _ready() -> void:
	label_ready_players.text = "Waiting for Players to Ready up \n0/" + str(NetworkManager.players.size())
	button_ready.pressed.connect(func(): rpc("ready_player"))
	if multiplayer.is_server():
		rpc("update_player_stats_from_server", SessionManager.player_stats)

func _process(_delta: float) -> void:
	if not multiplayer.is_server(): return
	var all_ready = ready_players.size() >= NetworkManager.players.size()
	if all_ready:
		if timer_start_round.is_stopped():
			timer_start_round.start(NEW_ROUND_TIMER)
			timer_start_round.timeout.connect(func(): NetworkManager.rpc("start_game"))
		rpc("update_all_ready_ui", timer_start_round.time_left)
	else:
		rpc("update_waiting_ui", ready_players.size(), NetworkManager.players.size())

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

func _update_stats():
	for child in player_stats.get_children(): child.queue_free()
	for peer_id in SessionManager.player_stats:
		var data = SessionManager.player_stats[peer_id]
		if typeof(data) == TYPE_DICTIONARY:
			var block = PLAYER_STAT_BLOCK.instantiate()
			player_stats.add_child(block, true)
			block.get_node("Panel/LabelUsername").text = str(data["username"])
			block.get_node("Panel/LabelMoney").text = "Money: " + str(data["money"])
			block.get_node("Panel/LabelWins").text = "Wins: " + str(data["wins"])
