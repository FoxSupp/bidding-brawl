class_name UpgradeHomingBullet
extends UpgradeBase

func _init() -> void:
	id += "homing_bullet"
	name = "Homing Bullets"
	description = "Your Bullets Home to the nearest enemy for " + str(GameConfig.get_homing_time_amount()) + " secs"

func apply(player: Player) -> void:
	player.upgrade_homing_time += GameConfig.get_homing_time_amount()
