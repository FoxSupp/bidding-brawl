class_name UpgradeBase
extends Resource

@export var id := "upgrade_"
@export var name: String
@export var description: String

func apply(_player: Player) -> void:
	push_error("apply() must be implemented in subclass")
