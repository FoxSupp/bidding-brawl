extends Control

@onready var v_box_container: VBoxContainer = $Background/VBoxContainer
@onready var button_start_game: Button = $Background/HBoxContainer/ButtonStartGame
@onready var button_main_menu: Button = $Background/HBoxContainer/ButtonMainMenu

const PLAYER_SLOT = preload("res://scenes/player_slot.tscn")

func _ready() -> void:
	SessionManager.clear_session()
	NetworkManager.players_updated.connect(_update_player_display)
	button_start_game.pressed.connect(_on_start_game_pressed)
	button_main_menu.pressed.connect(_on_main_menu_pressed)
	
	button_start_game.disabled = not NetworkManager.is_server()
	_update_player_display(NetworkManager.players)

func _update_player_display(_players: Dictionary) -> void:
	for child in v_box_container.get_children():
		child.queue_free()
	
	for peer_id in NetworkManager.players:
		var player_data = NetworkManager.players[peer_id]
		if typeof(player_data) == TYPE_DICTIONARY:
			var player_slot: Node = PLAYER_SLOT.instantiate()
			v_box_container.add_child(player_slot)
			
			var player_name_node: Label = player_slot.get_node_or_null("Background/HBoxContainer/PlayerName")
			if player_name_node:
				player_name_node.text = player_data.get("username", "Unknown")

func _on_start_game_pressed() -> void:
	if NetworkManager.is_server():
		NetworkManager.rpc("start_game")

func _on_main_menu_pressed() -> void:
	NetworkManager.disconnect_from_server()
