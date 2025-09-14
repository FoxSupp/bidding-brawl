class_name UpgradeHealth
extends UpgradeBase

func _init() -> void:
	id += "health"
	name = "Health"
	description = "+20 Max Life"

func apply(player: Player) -> void:
	player.upgrade_max_health += 20
