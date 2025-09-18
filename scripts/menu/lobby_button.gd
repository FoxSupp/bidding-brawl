extends Button

var join_lobby_id: int

func setup_button_data(button_text: String, lobby_id: int):
	text = button_text
	join_lobby_id = lobby_id
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	Steamworks.join_lobby(join_lobby_id)
