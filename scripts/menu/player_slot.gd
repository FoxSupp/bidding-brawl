extends Control

@onready var player_name_label: Label = $Background/HBoxContainer/PlayerName
@onready var ready_indicator: Panel = $Background/HBoxContainer/ReadyIndicator

func set_player_data(username: String, status: int) -> void:
	# Make sure nodes are ready before trying to access them
	if not is_node_ready():
		await ready
	
	if player_name_label:
		player_name_label.text = username
	
	if ready_indicator:
		# Create appropriate style based on status
		var style = StyleBoxFlat.new()
		style.corner_radius_top_left = 4
		style.corner_radius_top_right = 4
		style.corner_radius_bottom_right = 4
		style.corner_radius_bottom_left = 4
		
		match status:
			NetworkManager.PlayerStatus.CONNECTING:
				style.bg_color = Color(1, 0.8, 0.2, 1)  # Yellow
			NetworkManager.PlayerStatus.REGISTERED:
				style.bg_color = Color(0.2, 0.8, 0.3, 1)  # Green
			_:
				style.bg_color = Color(1, 0.8, 0.2, 1)  # Default to yellow
		
		ready_indicator.add_theme_stylebox_override("panel", style)
