extends Node

@onready var audio_button_click: AudioStreamPlayer = $AudioButtonClick

func _enter_tree() -> void:
	get_tree().node_added.connect(_on_node_added)

func _on_node_added(node: Node) -> void:
	if node is Button and node.is_in_group("sound_blip"):
		node.pressed.connect(_play_pressed)

func _play_pressed() -> void:
	audio_button_click.play()
	
