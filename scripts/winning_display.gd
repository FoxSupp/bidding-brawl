## Winning Display Controller
## Shows the final winner and their stats at the end of a match
extends Control

# UI references
@onready var winner_name_label: Label = $CenterContainer/MainPanel/VBoxContainer/WinnerNameLabel
@onready var kills_value: Label = $CenterContainer/MainPanel/VBoxContainer/StatsContainer/StatsPanel/StatsGrid/KillsValue
@onready var upgrades_value: Label = $CenterContainer/MainPanel/VBoxContainer/StatsContainer/StatsPanel/StatsGrid/UpgradesValue
@onready var play_again_button: Button = $CenterContainer/MainPanel/VBoxContainer/ButtonContainer/PlayAgainButton

func _ready() -> void:
	_setup_ui()

func _setup_ui() -> void:
	# Only show play again button for server
	if not multiplayer.is_server():
		play_again_button.hide()
		return
	
	# Display winner information
	if SessionManager.winner.is_empty():
		push_warning("No winner data available!")
		return
		
	winner_name_label.text = SessionManager.winner.get("username", "Unknown")
	kills_value.text = str(SessionManager.winner.get("kills", 0))
	upgrades_value.text = str(SessionManager.winner.get("upgrades", []).size())


func _on_main_menu_button_pressed() -> void:
	NetworkManager.disconnect_from_server()


func _on_play_again_button_pressed() -> void:
	NetworkManager.rpc("change_to_lobby")
