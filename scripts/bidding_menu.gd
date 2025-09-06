extends Control

signal player_ready

@export var ready_players: Array = []
@onready var button_ready: Button = $Background/ButtonReady
@onready var label_ready_players: Label = $Background/LabelReadyPlayers
@onready var player_stats: VBoxContainer = $Background/PlayerStats
const PLAYER_STAT_BLOCK = preload("res://scenes/player_stat_block.tscn")

func _ready() -> void:
	label_ready_players.text = "Waiting for Players to Ready up \n 0/" + str(NetworkManager.players.size())
	button_ready.pressed.connect(_ready_button_pressed)
	player_ready.connect(_update_display)
	_update_player_stats_display()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if multiplayer.is_server():
		if ready_players.size() >= NetworkManager.players.size():
			await get_tree().create_timer(1.5).timeout
			NetworkManager.rpc("start_game")

@rpc("any_peer", "call_local")
func ready_player():
	ready_players.append(multiplayer.get_remote_sender_id())
	emit_signal("player_ready")

func _ready_button_pressed():
	rpc("ready_player")

func _update_display():
	if ready_players.size() == NetworkManager.players.size():
		label_ready_players.text = "All Players Ready, Game Starting Soon"
	else:
		label_ready_players.text = "Waiting for Players to Ready up \n " + str(ready_players.size()) + "/" + str(NetworkManager.players.size())
	# Ready = all show text game starting soon

func _update_player_stats_display() -> void:
	for player_stat_block in player_stats.get_children():
		player_stat_block.queue_free()
	
	for peer_id in SessionManager.player_stats:
		var player_data = SessionManager.player_stats[peer_id]
		if typeof(player_data) == TYPE_DICTIONARY:
			var player_stat_block = PLAYER_STAT_BLOCK.instantiate()
			player_stats.add_child(player_stat_block)
			
			# Update the display with actual data
			player_stat_block.get_node("Panel/LabelUsername").text = str(player_data["username"])
			player_stat_block.get_node("Panel/LabelMoney").text = "Money: " + str(player_data["money"])
			player_stat_block.get_node("Panel/LabelWins").text = "Wins: " + str(player_data["wins"])
