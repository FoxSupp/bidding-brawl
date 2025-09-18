class_name UpgradeSpeed
extends UpgradeBase

func _init() -> void:
	id += "speed"
	name = "Speed"
	description = "Boosts Movementspeed by " + str(GameConfig.SPEED_UPGRADE_AMOUNT)

func apply(player: Player) -> void:
	player.upgrade_speed_bonus += GameConfig.SPEED_UPGRADE_AMOUNT
