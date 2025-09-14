extends Control

@onready var button_back: Button = $CenterContainer/ButtonBack

func _ready() -> void:
	button_back.pressed.connect(_on_button_back_pressed)

func _on_button_back_pressed() -> void:
	hide()
	get_parent().get_node("MainMenu").show()
