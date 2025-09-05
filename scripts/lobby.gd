extends Control

@onready var v_box_container: VBoxContainer = $Background/VBoxContainer
@onready var button_start_game: Button = $Background/HBoxContainer/ButtonStartGame
@onready var button_main_menu: Button = $Background/HBoxContainer/ButtonMainMenu

const PLAYER_SLOT = preload("res://scenes/player_slot.tscn")
const MENU_SCENE = preload("res://scenes/main_menu.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if has_node("/root/NetworkManager"):
		NetworkManager.players_updated.connect(_on_players_updated)
		_add_players_to_display()
	button_start_game.pressed.connect(_on_start_game_pressed)
	button_main_menu.pressed.connect(_on_main_menu_pressed)
	button_start_game.disabled = !NetworkManager.is_server()

func _add_players_to_display():
	# Delete all Players from the Display
	for c in v_box_container.get_children():
		c.queue_free()
	# Add all Players to the Lobby Display
        for peer_id in NetworkManager.players:
                var player_slot = PLAYER_SLOT.instantiate()
                v_box_container.add_child(player_slot)
                var player_name_node = player_slot.get_node_or_null("Background/PlayerName")
               player_name_node.text = NetworkManager.players[peer_id]['username']
               var stats_node = player_slot.get_node_or_null("Background/Stats")
               if stats_node:
                       var p = NetworkManager.players[peer_id]
                       stats_node.text = "W:%d L:%d WS:%d LS:%d" % [
                               p.get("wins", 0),
                               p.get("losses", 0),
                               p.get("win_streak", 0),
                               p.get("loss_streak", 0),
                       ]

func _on_players_updated(players: Dictionary) -> void:
	_add_players_to_display()

func _on_start_game_pressed() -> void:
	if NetworkManager.is_server():
		NetworkManager.rpc("start_game")

func _on_main_menu_pressed() -> void:
	NetworkManager.disconnect_from_server()
