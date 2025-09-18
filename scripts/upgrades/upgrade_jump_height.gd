class_name UpgradeJumpHeight
extends UpgradeBase

func _init() -> void:
	id += "jump_height"
	name = "Jump Height"
	description = "Boosts Jump Height"

func apply(player: Player) -> void:
	player.upgrade_jump_height += GameConfig.JUMP_HEIGHT_UPGRADE
