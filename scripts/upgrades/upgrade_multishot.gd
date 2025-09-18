class_name UpgradeMultishot
extends UpgradeBase

func _init() -> void:
	id += "multishot"
	name = "Multishot"
	description = "Shot +" + str(GameConfig.MULTISHOT_AMOUNT) + " Bullet"

func apply(player: Player) -> void:
	player.upgrade_multishot_count += GameConfig.MULTISHOT_AMOUNT
