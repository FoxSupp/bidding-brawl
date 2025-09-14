extends Control

@onready var multiplayer_menu: Control = $MultiplayerMenu
@onready var main_menu: Control = $MainMenu
@onready var options_menu: Control = $OptionsMenu
@onready var credits_menu: Control = $CreditsMenu
@onready var how_to_menu: Control = $HowToMenu

@onready var mult_button_back: Button = $MultiplayerMenu/VBox/Control/ButtonBack
@onready var opt_button_back: Button = $OptionsMenu/VBoxContainer/ButtonBack
@onready var cred_button_back: Button = $CreditsMenu/CenterContainer/ButtonBack
@onready var how_to_button_back: Button = $HowToMenu/CenterContainer/ButtonBack

@onready var menu_button_multiplayer: Button = $MainMenu/VBoxContainer/ButtonMultiplayer
@onready var menu_button_options: Button = $MainMenu/VBoxContainer/ButtonOptions
@onready var menu_button_credits: Button = $MainMenu/VBoxContainer/ButtonCredits
@onready var menu_button_how_to: Button = $MainMenu/VBoxContainer/ButtonHowTo
@onready var menu_button_quit_game: Button = $MainMenu/VBoxContainer/ButtonQuitGame


func _ready() -> void:

	menu_button_multiplayer.pressed.connect(_on_menu_button_multiplayer_pressed)
	menu_button_options.pressed.connect(_on_menu_button_options_pressed)
	menu_button_credits.pressed.connect(_on_menu_button_credits_pressed)
	menu_button_how_to.pressed.connect(_on_menu_button_how_to_pressed)
	menu_button_quit_game.pressed.connect(_on_menu_button_quit_game_pressed)
	
	mult_button_back.pressed.connect(_on_button_back_pressed)
	opt_button_back.pressed.connect(_on_button_back_pressed)
	cred_button_back.pressed.connect(_on_button_back_pressed)
	how_to_button_back.pressed.connect(_on_button_back_pressed)

func _on_menu_button_multiplayer_pressed() -> void:
	main_menu.hide()
	multiplayer_menu.show()

func _on_menu_button_options_pressed() -> void:
	main_menu.hide()
	options_menu.show()

func _on_menu_button_credits_pressed() -> void:
	main_menu.hide()
	credits_menu.show()

func _on_menu_button_how_to_pressed() -> void:
	main_menu.hide()
	how_to_menu.show()

func _on_menu_button_quit_game_pressed() -> void:
	get_tree().quit()

func _on_button_back_pressed() -> void:
	main_menu.show()
	multiplayer_menu.hide()
	options_menu.hide()
	credits_menu.hide()
	how_to_menu.hide()
