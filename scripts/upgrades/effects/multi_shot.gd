extends WeaponEffect
class_name MultiShotEffect
@export var spread_deg: float = 6.0

func _init():
	upgrade_name = "Multi shot"

func on_fire(ctx: Dictionary) -> Dictionary:
	ctx.projectile_count = max(2, int(ctx.get("projectile_count", 1) + 1))
	spread_deg = ctx.projectile_count * 3
	ctx.spread_pattern = "symmetric"
	ctx.spread_deg = spread_deg
	return ctx
