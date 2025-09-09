extends WeaponEffect
class_name Test

func _init():
	upgrade_name = "Test Upgrade"

func on_fire(ctx: Dictionary) -> Dictionary:
	return ctx
