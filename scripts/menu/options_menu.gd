extends Control

@onready var slider_main_volume: HSlider = $VBoxContainer/SliderMainVolume
@onready var slider_music_volume: HSlider = $VBoxContainer/SliderMusicVolume
@onready var slider_sound_effect_volume: HSlider = $VBoxContainer/SliderSoundEffectVolume

var master_bus_id: int
var music_bus_id: int
var sound_effect_bus_id: int

const CONFIG_FILE_PATH = "user://settings.cfg"

func _ready() -> void:
	master_bus_id = AudioServer.get_bus_index("Master")
	music_bus_id = AudioServer.get_bus_index("Music")
	sound_effect_bus_id = AudioServer.get_bus_index("SoundEffect")

	load_settings()
	
	

	slider_main_volume.value_changed.connect(_on_volume_changed)
	slider_music_volume.value_changed.connect(_on_volume_changed)
	slider_sound_effect_volume.value_changed.connect(_on_volume_changed)

func _on_volume_changed(_value: float) -> void:
	save_settings()

func _process(_delta: float) -> void:
	AudioServer.set_bus_volume_linear(master_bus_id, slider_main_volume.value / 100)
	AudioServer.set_bus_volume_linear(music_bus_id, slider_music_volume.value / 100)
	AudioServer.set_bus_volume_linear(sound_effect_bus_id, slider_sound_effect_volume.value / 100)

func load_settings() -> void:
	var config = ConfigFile.new()
	var err = config.load(CONFIG_FILE_PATH)
	
	if err != OK:
		# If file doesn't exist or can't be loaded, use default values
		slider_main_volume.value = 100
		slider_music_volume.value = 100
		slider_sound_effect_volume.value = 100
	else:
		# Load saved values, with defaults if keys don't exist
		slider_main_volume.value = config.get_value("audio", "master_volume", 100)
		slider_music_volume.value = config.get_value("audio", "music_volume", 100)
		slider_sound_effect_volume.value = config.get_value("audio", "sound_effect_volume", 100)

func save_settings() -> void:
	var config = ConfigFile.new()
	
	config.set_value("audio", "master_volume", slider_main_volume.value)
	config.set_value("audio", "music_volume", slider_music_volume.value)
	config.set_value("audio", "sound_effect_volume", slider_sound_effect_volume.value)
	
	config.save(CONFIG_FILE_PATH)
	
	
