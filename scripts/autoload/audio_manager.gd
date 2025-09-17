## Audio Manager Singleton
## Handles global audio playback and automatic button sound integration
extends Node

@onready var audio_button_click: AudioStreamPlayer = $AudioButtonClick

func _enter_tree() -> void:
	# Connect to tree signals for automatic button sound integration
	get_tree().node_added.connect(_on_node_added)

func _on_node_added(node: Node) -> void:
	# Automatically connect button sounds for nodes in the "sound_blip" group
	if node is Button and node.is_in_group("sound_blip"):
		# Avoid duplicate connections
		if not node.pressed.is_connected(_play_pressed):
			node.pressed.connect(_play_pressed)

func _play_pressed() -> void:
	if audio_button_click:
		audio_button_click.play()

## Play a button click sound manually
func play_button_sound() -> void:
	_play_pressed()

## Set global audio volume (if needed for future expansion)
func set_master_volume(volume_db: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), volume_db)

## Set volume for a specific audio bus
func set_bus_volume(bus_name: String, volume_db: float) -> void:
	var bus_index = AudioServer.get_bus_index(bus_name)
	if bus_index != -1:
		AudioServer.set_bus_volume_db(bus_index, volume_db)
	else:
		push_warning("Audio bus not found: " + bus_name)

## Mute/unmute a specific audio bus
func set_bus_mute(bus_name: String, muted: bool) -> void:
	var bus_index = AudioServer.get_bus_index(bus_name)
	if bus_index != -1:
		AudioServer.set_bus_mute(bus_index, muted)
	else:
		push_warning("Audio bus not found: " + bus_name)

## Get current volume of a bus
func get_bus_volume(bus_name: String) -> float:
	var bus_index = AudioServer.get_bus_index(bus_name)
	if bus_index != -1:
		return AudioServer.get_bus_volume_db(bus_index)
	else:
		push_warning("Audio bus not found: " + bus_name)
		return 0.0

## Check if a bus is muted
func is_bus_muted(bus_name: String) -> bool:
	var bus_index = AudioServer.get_bus_index(bus_name)
	if bus_index != -1:
		return AudioServer.is_bus_mute(bus_index)
	else:
		push_warning("Audio bus not found: " + bus_name)
		return false
