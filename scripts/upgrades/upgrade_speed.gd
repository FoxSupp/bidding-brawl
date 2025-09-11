class_name UpgradeSpeed
extends UpgradeBase

func _init() -> void:
	id += "speed"
	name = "Speed"
	description = "Boosts Movementspeed by 50"

func apply(player: Player) -> void:
	player.upgrade_speed_bonus += 50
