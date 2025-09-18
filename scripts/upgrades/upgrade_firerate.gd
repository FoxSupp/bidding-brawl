class_name UpgradeFirerate
extends UpgradeBase

func _init() -> void:
	id += "firerate"
	name = "Firerate"
	description = "Shoot 10% faster"

func apply(player: Player) -> void:
	player.upgrade_firerate_multiplier *= GameConfig.FIRERATE_MULTIPLIER
