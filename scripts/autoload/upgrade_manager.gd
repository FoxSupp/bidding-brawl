extends Node

var upgrade_types: Array[UpgradeBase] = []

func _ready() -> void:
	upgrade_types = [
		UpgradeFirerate.new(),
		UpgradeMultishot.new(),
		UpgradeHealth.new(),
		UpgradeSpeed.new(),
		UpgradeJumpHeight.new(),
		UpgradeMultijump.new(),
		UpgradeBulletBounce.new(),
		UpgradeHomingBullet.new(),
	]

func apply_upgrade(player: Player, upgrade_id: String) -> bool:
	var upgrade = get_upgrade_by_id(upgrade_id)
	if upgrade:
		#upgrade.apply(player)
		player.upgrades.append(upgrade)
		return true
	return false

func get_upgrade_by_id(id: String) -> UpgradeBase:
	for upgrade in upgrade_types:
		if upgrade.id == id:
			return upgrade
	return null

func get_random_upgrade() -> UpgradeBase:
	if upgrade_types.size() > 0:
		return upgrade_types[randi() % upgrade_types.size()]
	return null
