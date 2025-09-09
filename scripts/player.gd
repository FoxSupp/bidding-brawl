class_name Player
extends CharacterBody2D

signal died(player_id: int)

@onready var input_synch: Node2D = $InputSynch
@onready var muzzle_rotation: Node2D = $MuzzleRotation
@onready var hp_bar: ProgressBar = $HP/HPBar
@onready var camera: Camera2D = $Camera2D
@onready var color_rect: ColorRect = $ColorRect
@onready var collision: CollisionShape2D = $CollisionShape2D

const SPEED: float = 300.0
const JUMP_VELOCITY: float = -400.0
const KILL_MONEY: int = 100
const BULLET_SCENE = preload("res://scenes/bullet.tscn")

var spectating_cam: Camera2D
var _weapon_effects: Array[WeaponEffect]

@export var health: int = 5
@export var score: int = 0
@export var dead: bool = false

func _enter_tree() -> void:
	get_node("InputSynch").set_multiplayer_authority(name.to_int())

func _ready() -> void:
	spectating_cam = get_tree().root.get_node("/root/Game/Camera2D")
	hp_bar.max_value = health
	hp_bar.value = health
	_load_persistent_weapon_effects()
	
	if input_synch.is_multiplayer_authority():
		color_rect.color = Color.YELLOW

# DEBUG
func _process(delta: float) -> void:
	if not multiplayer.is_server():
		return
	if Input.is_action_just_pressed("debug_1"):
		var eff = MultiShotEffect.new()
		add_weapon_upgrade_effect(eff)

func _physics_process(delta: float) -> void:
	if input_synch.is_multiplayer_authority():
		camera.enabled = not dead
		spectating_cam.enabled = dead
	
	if not is_multiplayer_authority() or dead:
		return
	
	_handle_movement(delta)
	_handle_aiming()
	_handle_shooting()
	
	if health <= 0:
		_handle_death()

func _handle_movement(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if input_synch.jump_input and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	velocity.x = input_synch.move_input * SPEED if input_synch.move_input else move_toward(velocity.x, 0, SPEED)
	move_and_slide()

func add_weapon_upgrade_effect(effect: WeaponEffect) -> void:
	if multiplayer.is_server():
		_weapon_effects.append(effect)
		SessionManager.rpc("addWeaponEffect", name.to_int(), effect)

func _load_persistent_weapon_effects() -> void:
	var persistent_effects = SessionManager.getWeaponEffects(name.to_int())
	_weapon_effects = persistent_effects.duplicate(true)




func _handle_aiming() -> void:
	muzzle_rotation.rotation = (input_synch.mouse_pos - position).angle()

func _handle_shooting() -> void:
	if not input_synch.fire_input:
		return
	
	var muzzle: Marker2D = muzzle_rotation.get_node("Muzzle")
	var dir := muzzle.global_position.direction_to(input_synch.mouse_pos).normalized()
	var ctx := {
		"muzzle_pos": muzzle.global_position,
		"dir": dir,
		"projectile_count": 1,
		"spread_pattern": "none",
		"spread_deg": 0.0,
		"damage": 1,
		"speed": 900.0,
		"lifetime": 1.2,
		"owner_peer_id": name.to_int()
	}
	
	for e in _weapon_effects:
		ctx = e.on_fire(ctx)
	
	var dirs: Array[Vector2] = []
	match String(ctx.spread_pattern):
		"symmetric":
			var count := int(ctx.projectile_count)
			if count <= 1:
				dirs = [ctx.dir]
			elif count == 2:
				var a := deg_to_rad(float(ctx.spread_deg))
				dirs = [ctx.dir.rotated(-a), ctx.dir.rotated(a)]
			else:
				var total = max(count, 1)
				var span := 2.0 * float(ctx.spread_deg)
				var step := 0.0 if total <= 1 else span / float(total - 1)
				for i in range(total):
					var offset := -float(ctx.spread_deg) + step * i
					dirs.append(ctx.dir.rotated(deg_to_rad(offset)))
		_:
			dirs = [ctx.dir]
	var projectiles_root := get_tree().root.get_node("Game/Projectiles")
	for d in dirs:
		var projectile: Node = BULLET_SCENE.instantiate()
		projectile.global_position = ctx.muzzle_pos
		projectile.rotation = d.angle()
		projectile.dir = d
		projectile.owner_peer_id = name.to_int()
		
		if "damage" in projectile: projectile.damage = ctx.damage
		if "speed" in projectile: projectile.speed = ctx.speed
		if "lifetime" in projectile: projectile.lifetime = ctx.lifetime
		projectiles_root.add_child(projectile, true)

func _handle_death() -> void:
	dead = true
	visible = false
	collision.disabled = true
	
	if input_synch.is_multiplayer_authority():
		input_synch.set_multiplayer_authority(1)
	
	died.emit(name.to_int())

func take_damage(damage: int, shooter_id: int) -> void:
	if not is_multiplayer_authority():
		return
	
	health -= damage
	hp_bar.value = health
	
	if health <= 0 and shooter_id != name.to_int():
		SessionManager.rpc("addMoney", shooter_id, KILL_MONEY)

func despawn_player() -> void:
	dead = true
	if not is_multiplayer_authority():
		return
	# Safe node access to prevent null reference errors
	var input_synch_node = input_synch.get_node_or_null("InputSynch")
	if input_synch_node and is_instance_valid(input_synch_node):
		input_synch_node.public_visibility = false
	await get_tree().process_frame
	queue_free()
