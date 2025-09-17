class_name UpgradeHealth
extends UpgradeBase

func _init() -> void:
	id += "health"
	name = "Health"
	description = "+" + str(GameConfig.HEALTH_UPGRADE_AMOUNT) + " Max Life"

func apply(player: Player) -> void:
	player.upgrade_max_health += GameConfig.HEALTH_UPGRADE_AMOUNT
