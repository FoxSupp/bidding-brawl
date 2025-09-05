class_name MainMenu
extends Control

@onready var user_input: LineEdit = $CenterContainer/VBox/Grid/UserInput
@onready var ip_input: LineEdit = $CenterContainer/VBox/Grid/IpInput
@onready var port_input: LineEdit = $CenterContainer/VBox/Grid/PortInput
@onready var host_button: Button = $CenterContainer/VBox/Buttons/HostButton
@onready var join_button: Button = $CenterContainer/VBox/Buttons/JoinButton
@onready var status_label: Label = $CenterContainer/VBox/Status

func _ready() -> void:
    if has_node("/root/NetworkManager"):
        NetworkManager.error.connect(_on_error)
    host_button.pressed.connect(_on_host_pressed)
    join_button.pressed.connect(_on_join_pressed)
    user_input.text = OS.get_cmdline_args()[1]

func _on_host_pressed() -> void:
    var username: String = user_input.text
    var port_text: String = port_input.text.strip_edges()
    if not _is_valid_port(port_text):
        _on_error("Invalid port number")
        return
    var port: int = int(port_text)
    if has_node("/root/NetworkManager"):
        NetworkManager.host(port, username)

func _on_join_pressed() -> void:
    var username: String = user_input.text
    var ip: String = ip_input.text
    var port_text: String = port_input.text.strip_edges()
    if not _is_valid_port(port_text):
        _on_error("Invalid port number")
        return
    var port: int = int(port_text)
    if has_node("/root/NetworkManager"):
        NetworkManager.join(ip, port, username)

func _on_error(msg: String) -> void:
    status_label.text = msg
    status_label.modulate = Color(1, 0.6, 0.6, 1)
    await get_tree().process_frame
    await get_tree().create_timer(2.0).timeout
    status_label.modulate = Color(1, 1, 1, 0.9)

func _is_valid_port(text: String) -> bool:
    if not text.is_valid_int():
        return false
    var p: int = int(text)
    return p > 0 and p < 65536
