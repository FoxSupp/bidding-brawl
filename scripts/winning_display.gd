extends Control

@onready var winner_name_label: Label = $CenterContainer/MainPanel/VBoxContainer/WinnerNameLabel
@onready var kills_value: Label = $CenterContainer/MainPanel/VBoxContainer/StatsContainer/StatsPanel/StatsGrid/KillsValue
@onready var upgrades_value: Label = $CenterContainer/MainPanel/VBoxContainer/StatsContainer/StatsPanel/StatsGrid/UpgradesValue
@onready var play_again_button: Button = $CenterContainer/MainPanel/VBoxContainer/ButtonContainer/PlayAgainButton

func _ready() -> void:
	if not multiplayer.is_server():
		play_again_button.hide()
		return
	winner_name_label.text = SessionManager.winner.username
	kills_value.text = str(SessionManager.winner.kills)
	upgrades_value.text = str(SessionManager.winner.upgrades.size())


func _on_main_menu_button_pressed() -> void:
	NetworkManager.disconnect_from_server()


func _on_play_again_button_pressed() -> void:
	NetworkManager.rpc("change_to_lobby")
