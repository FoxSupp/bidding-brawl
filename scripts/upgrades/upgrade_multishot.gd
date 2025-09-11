class_name UpgradeMultishot
extends UpgradeBase

func _init() -> void:
	id += "multishot"
	name = "Multishot"
	description = "Shot +1 Bullet"

func apply(player: Player) -> void:
	player.upgrade_multishot_count += 1
