class_name UpgradeBulletBounce
extends UpgradeBase

func _init() -> void:
	id += "bullet_bounce"
	name = "Bullet Bounce"
	description = "Lets your Bullet bounce +" + str(GameConfig.BULLET_BOUNCE_AMOUNT)

func apply(player: Player) -> void:
	player.upgrade_bounce_count += GameConfig.BULLET_BOUNCE_AMOUNT
