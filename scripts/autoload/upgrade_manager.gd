## Upgrade Manager Singleton
## Manages available upgrades and applies them to players
extends Node

var upgrade_types: Array[UpgradeBase] = []

func _ready() -> void:
	_initialize_upgrades()

func _initialize_upgrades() -> void:
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
	
	print("Initialized %d upgrade types" % upgrade_types.size())

func apply_upgrade(player: Player, upgrade_id: String) -> bool:
	var upgrade = get_upgrade_by_id(upgrade_id)
	if not upgrade:
		push_error("Failed to find upgrade with ID: " + upgrade_id)
		return false
		
	player.upgrades.append(upgrade)
	return true

func get_upgrade_by_id(id: String) -> UpgradeBase:
	for upgrade in upgrade_types:
		if upgrade.id == id:
			return upgrade
	return null

func get_random_upgrade() -> UpgradeBase:
	if upgrade_types.is_empty():
		push_error("No upgrade types available!")
		return null
		
	return upgrade_types[randi() % upgrade_types.size()]

## Get all available upgrade IDs
func get_all_upgrade_ids() -> Array[String]:
	var ids: Array[String] = []
	for upgrade in upgrade_types:
		ids.append(upgrade.id)
	return ids

## Get upgrade by name (useful for debugging)
func get_upgrade_by_name(upgrade_name: String) -> UpgradeBase:
	for upgrade in upgrade_types:
		if upgrade.name == upgrade_name:
			return upgrade
	return null

## Get multiple random upgrades without duplicates
func get_random_upgrades(count: int) -> Array[UpgradeBase]:
	if count <= 0 or upgrade_types.is_empty():
		return []
	
	var available_upgrades = upgrade_types.duplicate()
	var selected_upgrades: Array[UpgradeBase] = []
	
	for i in range(min(count, available_upgrades.size())):
		var random_index = randi() % available_upgrades.size()
		selected_upgrades.append(available_upgrades[random_index])
		available_upgrades.remove_at(random_index)
	
	return selected_upgrades
