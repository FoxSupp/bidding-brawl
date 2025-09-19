class_name UpgradeSpeed
extends UpgradeBase

func _init() -> void:
	id += "speed"
	name = "Speed"
	description = "Boosts Movementspeed by " + str(GameConfig.get_speed_upgrade_amount())

func apply(player: Player) -> void:
	player.upgrade_speed_bonus += GameConfig.get_speed_upgrade_amount()
