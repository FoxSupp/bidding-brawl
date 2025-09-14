class_name UpgradeJumpHeight
extends UpgradeBase

func _init() -> void:
	id += "jump_height"
	name = "Jump Height"
	description = "Boosts Jump Height by 5%"

func apply(player: Player) -> void:
	player.upgrade_jump_height += 50
