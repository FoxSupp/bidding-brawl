class_name UpgradeBulletBounce
extends UpgradeBase

func _init() -> void:
	id += "bullet_bounce"
	name = "Bullet Bounce"
	description = "Lets your Bullet bounce +1"

func apply(player: Player) -> void:
	player.upgrade_bounce_count += 1
