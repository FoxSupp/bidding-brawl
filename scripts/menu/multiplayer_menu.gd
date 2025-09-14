extends Control

@onready var user_input: LineEdit = $VBox/Grid/UserInput
@onready var ip_input: LineEdit = $VBox/Grid/IpInput
@onready var port_input: LineEdit = $VBox/Grid/PortInput
@onready var host_button: Button = $VBox/Buttons/HostButton
@onready var join_button: Button = $VBox/Buttons/JoinButton
@onready var status_label: Label = $VBox/Status

const MIN_PORT: int = 1
const MAX_PORT: int = 65535
const ERROR_DISPLAY_DURATION: float = 2.0

func _ready() -> void:
	NetworkManager.error.connect(_on_error)
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)
	
	var cmd_args: PackedStringArray = OS.get_cmdline_args()
	if cmd_args.size() > 1:
		user_input.text = cmd_args[1]

func _on_host_pressed() -> void:
	var port_text: String = port_input.text.strip_edges()
	if not _is_valid_port(port_text):
		_on_error("Invalid port number")
		return
	
	NetworkManager.host(int(port_text), user_input.text)

func _on_join_pressed() -> void:
	var port_text: String = port_input.text.strip_edges()
	if not _is_valid_port(port_text):
		_on_error("Invalid port number")
		return
	
	NetworkManager.join(ip_input.text, int(port_text), user_input.text)

func _on_error(msg: String) -> void:
	status_label.text = msg
	status_label.modulate = Color(1, 0.6, 0.6, 1)
	await get_tree().process_frame
	await get_tree().create_timer(ERROR_DISPLAY_DURATION).timeout
	status_label.modulate = Color(1, 1, 1, 0.9)

func _is_valid_port(text: String) -> bool:
	return text.is_valid_int() and int(text) in range(MIN_PORT, MAX_PORT + 1)


func _on_button_back_pressed() -> void:
	hide()
	$"../MainMenu".show()
