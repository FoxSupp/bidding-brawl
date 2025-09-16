class_name UpgradeMultijump
extends UpgradeBase

func _init() -> void:
	id += "multijump"
	name = "Multijump"
	description = "Jump +1 Time"

func apply(player: Player) -> void:
	player.upgrade_multijump_count += 1
