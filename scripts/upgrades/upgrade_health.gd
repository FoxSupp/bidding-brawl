class_name UpgradeHealth
extends UpgradeBase

func _init() -> void:
	id += "health"
	name = "Health"
	description = "+" + str(GameConfig.get_health_upgrade_amount()) + " Max Life"

func apply(player: Player) -> void:
	player.upgrade_max_health += GameConfig.get_health_upgrade_amount()
