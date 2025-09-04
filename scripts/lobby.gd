extends Control

@onready var v_box_container: VBoxContainer = $Background/VBoxContainer
@onready var button_start_game: Button = $Background/HBoxContainer/ButtonStartGame
@onready var button_main_menu: Button = $Background/HBoxContainer/ButtonMainMenu

const PLAYER_SLOT = preload("res://scenes/player_slot.tscn")
const MENU_SCENE = preload("res://scenes/main_menu.tscn")
var nm

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if has_node("/root/NetworkManager"):
		print("MANAGER")
		nm = get_node("/root/NetworkManager")
		nm.players_updated.connect(_on_players_updated)
		_add_players_to_display()
	button_start_game.pressed.connect(_on_start_game_pressed)
	button_main_menu.pressed.connect(_on_main_menu_pressed)
	button_start_game.disabled = !nm.is_server()


	
func _add_players_to_display():
	for c in v_box_container.get_children():
		c.queue_free()
	for peer_id in nm.players:
		print(nm.players[peer_id])
		var player_slot = PLAYER_SLOT.instantiate()
		v_box_container.add_child(player_slot)
		var player_name_node = player_slot.get_node_or_null("Background/PlayerName")
		if player_name_node and player_name_node is Label:
			player_name_node.text = nm.players[peer_id]
		else:
			print("Could not find PlayerName node in player_slot")

func _on_players_updated(players: Dictionary) -> void:
	print(players)
	_add_players_to_display()

func _on_start_game_pressed() -> void:
	nm.start_game()

func _on_main_menu_pressed() -> void:
	nm.disconnect_from_server()
