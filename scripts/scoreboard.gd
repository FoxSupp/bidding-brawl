## Scoreboard UI Controller
## Displays player statistics during game
extends CanvasLayer

@onready var player_list: VBoxContainer = $ScoreboardPanel/VBoxContainer/PlayerList


func _ready() -> void:
	# Initially hidden
	visible = false
	
	# Connect to player stats updates
	if not SessionManager.player_stats_received.is_connected(_on_player_stats_updated):
		SessionManager.player_stats_received.connect(_on_player_stats_updated)

func _on_player_stats_updated(_peer_id: int, _stats: Dictionary) -> void:
	# Update scoreboard if it's currently visible
	if visible:
		update_scoreboard()

func show_scoreboard() -> void:
	visible = true
	update_scoreboard()

func hide_scoreboard() -> void:
	visible = false

func update_scoreboard() -> void:
	# Clear existing player rows
	for child in player_list.get_children():
		child.queue_free()
	
	# Add current players
	var game_node = get_tree().get_first_node_in_group("game")
	if not game_node:
		return
	
	var players_node = game_node.get_node_or_null("Players")
	if not players_node:
		return
	
	# Check if we have any player stats
	if SessionManager.player_stats.is_empty():
		# Request stats from server if we're a client and have no stats
		if not multiplayer.is_server():
			print("Scoreboard: No player stats available on client, requesting from server...")
		return
	
	# Get all players (alive and dead)
	var all_players = []
	for player_id in SessionManager.player_stats.keys():
		var player_data = SessionManager.get_player_display_stats(player_id)
		if player_data.is_empty():
			continue
			
		var player_node = players_node.get_node_or_null(str(player_id))
		var is_alive = player_node != null and not player_node.dead
		
		all_players.append({
			"id": player_id,
			"username": player_data.username,
			"kills": player_data.kills,
			"wins": player_data.wins,
			"money": player_data.money,
			"alive": is_alive
		})
	
	# Sort by wins, then kills
	all_players.sort_custom(func(a, b): 
		if a.wins == b.wins:
			return a.kills > b.kills
		return a.wins > b.wins
	)
	
	# Create UI rows for each player
	for player_data in all_players:
		var row = create_player_row(player_data)
		player_list.add_child(row)

func create_player_row(player_data: Dictionary) -> Control:
	var row = HBoxContainer.new()
	
	# Player name
	var name_label = Label.new()
	name_label.text = player_data.username
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if not player_data.alive:
		name_label.modulate = Color.GRAY
	row.add_child(name_label)
	
	# Kills
	var kills_label = Label.new()
	kills_label.text = str(player_data.kills)
	kills_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kills_label.custom_minimum_size.x = 80
	row.add_child(kills_label)
	
	# Wins 
	var wins_label = Label.new()
	wins_label.text = str(player_data.wins)
	wins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wins_label.custom_minimum_size.x = 80
	row.add_child(wins_label)
	
	# Money
	var money_label = Label.new()
	money_label.text = str(player_data.money)
	money_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	money_label.custom_minimum_size.x = 80
	row.add_child(money_label)
	
	# Status
	var status_label = Label.new()
	status_label.text = "ALIVE" if player_data.alive else "DEAD"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.custom_minimum_size.x = 80
	if player_data.alive:
		status_label.modulate = Color.GREEN
	else:
		status_label.modulate = Color.RED
	row.add_child(status_label)
	
	return row
