class_name UpgradeMultijump
extends UpgradeBase

func _init() -> void:
	id += "multijump"
	name = "Multijump"
	description = "Jump +" + str(GameConfig.MULTIJUMP_AMOUNT) + " Time"

func apply(player: Player) -> void:
	player.upgrade_multijump_count += GameConfig.MULTIJUMP_AMOUNT
