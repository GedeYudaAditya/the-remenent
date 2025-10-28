extends CharacterBody2D
@onready var sprite_2d: AnimatedSprite2D = $Sprite2D
@onready var jetpack_trail: CPUParticles2D = $JetpackTrail

# === CONFIGURATIONS ===
@export var speed := 80.0
@export var jump_force := -180.0
@export var gravity := 500.0
@export var low_gravity := 200.0
@export var max_jump_time := 0.5

@export var acceleration := 380.0
@export var friction := 380.0

# === THROW CONFIG ===
@export var throw_angle := 60.0
@export var max_throw_force := 350.0
@export var min_throw_force := 150.0

# === JETPACK CONFIG ===
@export var jetpack_unlocked := false
@export_enum("Booster_0_8", "Booster_2_0") var jetpack_type := "Booster_2_0"
@export var jetpack_force := -150.0
@export var jetpack_energy_max := 3.0
@export var jetpack_recharge_rate := 1.5
@export var jetpack_dash_force := 240.0
@export var jetpack_dash_cost := 0.4        # energi per dash
@export var jetpack_dash_cooldown := 0.2    # waktu antar dash (detik)

var jetpack_energy := 0.0
var is_using_jetpack := false
var jet_dash_cooldown_timer := 0.0

# === RUNTIME VARIABLES ===
var held_item: Node = null
var was_on_floor := true
var jump_time := 0.0
var hold_time := 0.0
var is_looking_back := false
var look_back_timer := 0.0
var aim_direction := Vector2.RIGHT

func _ready():
	jetpack_energy = jetpack_energy_max

func _process(delta):
	handle_attack_input()

func _physics_process(delta):
	var direction := Input.get_axis("left", "right")
	var looking_up := Input.is_action_pressed("up")
	var looking_down := Input.is_action_pressed("down")
	var jump_pressed := Input.is_action_pressed("jump")
	var jump_just_pressed := Input.is_action_just_pressed("jump")

	if jet_dash_cooldown_timer > 0:
		jet_dash_cooldown_timer -= delta

	# === GERAK HORIZONTAL ===
	if direction != 0:
		velocity.x = move_toward(velocity.x, direction * speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)

	# === GRAVITASI, LOMPAT, & JETPACK ===
	if is_on_floor():
		jetpack_trail.emitting = false
		jump_time = 0.0
		is_using_jetpack = false
		jetpack_energy = min(jetpack_energy + jetpack_recharge_rate * delta, jetpack_energy_max)

		if jump_just_pressed:
			velocity.y = jump_force
			sprite_2d.play("jump")

	else:
		# === BOOSTER 2.0 ===
		if jetpack_unlocked and jetpack_type == "Booster_2_0" and jump_pressed:
			if jetpack_energy > 0.0:
				is_using_jetpack = true
				velocity.y = move_toward(velocity.y, jetpack_force, 400 * delta)
				jetpack_energy = max(jetpack_energy - delta, 0.0)
				jetpack_trail.emitting = true   # 🔥 nyalakan asap
			else:
				is_using_jetpack = false
				jetpack_trail.emitting = false


		# === BOOSTER 0.8 MULTI DASH ===
		elif jetpack_unlocked and jetpack_type == "Booster_0_8" and jump_just_pressed:
			if jetpack_energy > 0.0 and jet_dash_cooldown_timer <= 0:
				is_using_jetpack = true
				jet_dash_cooldown_timer = jetpack_dash_cooldown
				jetpack_energy = max(jetpack_energy - jetpack_dash_cost, 0.0)

				var jet_dir := Vector2.ZERO
				if Input.is_action_pressed("up"):
					jet_dir.y = -1
				if Input.is_action_pressed("down"):
					jet_dir.y = 1
				if Input.is_action_pressed("left"):
					jet_dir.x = -1
				if Input.is_action_pressed("right"):
					jet_dir.x = 1
				if jet_dir == Vector2.ZERO:
					jet_dir = Vector2.UP

				velocity = jet_dir.normalized() * jetpack_dash_force
				sprite_2d.play("jetpack")
				
				# 🔥 aktifkan efek asap sebentar
				jetpack_trail.emitting = true
				jetpack_trail.restart()
			else:
				is_using_jetpack = false
				jetpack_trail.emitting = false
		else:
			is_using_jetpack = false

		# === NORMAL FALL PHYSICS ===
		if not is_using_jetpack:
			jetpack_trail.emitting = false
			if jump_pressed and jump_time < max_jump_time and velocity.y < 0:
				velocity.y += low_gravity * delta
				jump_time += delta
			else:
				velocity.y += gravity * delta

	move_and_slide()
	_check_tile_damage()

	# === ANIMASI ===
	if not is_on_floor():
		if is_using_jetpack:
			sprite_2d.play("jetpack")
		elif looking_down:
			sprite_2d.play("look_down")
		elif looking_up:
			sprite_2d.play("jump_look_up")
		else:
			sprite_2d.play("jump")
	else:
		if looking_up:
			if abs(direction) > 0:
				sprite_2d.play("run_look_up")
			else:
				sprite_2d.play("look_up")
		elif Input.is_action_just_pressed("down"):
			is_looking_back = true
			look_back_timer = 0.7
			sprite_2d.play("look_back")
		elif is_looking_back:
			if Input.is_action_just_released("down") \
			or abs(direction) > 0 \
			or looking_up \
			or Input.is_action_pressed("jump") \
			or Input.is_action_pressed("attack"):
				is_looking_back = false
				sprite_2d.play("idle")
			else:
				look_back_timer -= delta
				if look_back_timer <= 0.0:
					is_looking_back = false
					sprite_2d.play("idle")
		elif not is_looking_back:
			if abs(direction) > 0:
				sprite_2d.play("run")
			else:
				sprite_2d.play("idle")

	# === PICK / DROP ITEM ===
	if Input.is_action_just_pressed("pick"):
		if held_item:
			drop_item()
		else:
			pick_up_item()

	# === THROW ITEM ===
	if held_item:
		if Input.is_action_pressed("throw"):
			hold_time += delta
		elif Input.is_action_just_released("throw"):
			throw_item(looking_up)

	# === ARAH SPRITE ===
	if direction != 0:
		sprite_2d.flip_h = direction < 0

	# === AIM DIRECTION ===
	if not is_on_floor() and Input.is_action_pressed("down"):
		aim_direction = Vector2.DOWN
	elif Input.is_action_pressed("up"):
		aim_direction = Vector2.UP
	elif sprite_2d.flip_h:
		aim_direction = Vector2.LEFT
	else:
		aim_direction = Vector2.RIGHT


# =======================================
# === ITEM SYSTEM & WEAPON
# =======================================
func pick_up_item():
	var space_state = get_world_2d().direct_space_state
	var shape = RectangleShape2D.new()
	shape.extents = Vector2(5, 5)
	var direction: Vector2 = Vector2.LEFT if sprite_2d.flip_h else Vector2.RIGHT
	var check_pos = global_position + direction * 8
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0, check_pos)
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var result = space_state.intersect_shape(query)
	for r in result:
		var area = r.collider
		var parent = area.get_parent() if area else null
		if parent and parent.has_method("pick_up") and not parent.is_held:
			parent.pick_up(self)
			held_item = parent
			return

func drop_item():
	if held_item:
		held_item.drop(global_position + Vector2(0, 10))
		held_item = null

func throw_item(looking_up: bool):
	if held_item:
		var t = clamp(hold_time, 0.1, 1.0)
		var force = lerp(min_throw_force, max_throw_force, t)
		var dir: Vector2
		if looking_up:
			dir = Vector2(0, -1)
		else:
			var base_dir = Vector2.RIGHT if not sprite_2d.flip_h else Vector2.LEFT
			var angle_radians = deg_to_rad(throw_angle)
			dir = base_dir.rotated(-angle_radians if not sprite_2d.flip_h else angle_radians)
		held_item.drop(global_position + Vector2(0, -10), dir.normalized() * force)
		held_item = null
		hold_time = 0.0

func handle_attack_input():
	var attack_auto := Input.is_action_pressed("attack")
	var attack := Input.is_action_just_pressed("attack")
	if held_item and held_item is WeaponBase:
		var weapon = held_item as WeaponBase
		if weapon.automatic:
			if attack_auto:
				weapon.use()
		else:
			if attack:
				weapon.use()
		if Input.is_action_just_released("attack"):
			weapon.stop_use()

func _check_tile_damage():
	var tilemap = get_parent().get_node("TileMapLayer")  # sesuaikan nama node TileMap kamu
	if not tilemap:
		return
	
	# Cek tile di posisi player (gunakan global_position)
	var tile_pos = tilemap.local_to_map(tilemap.to_local(global_position))
	var tile_data = tilemap.get_cell_tile_data(tile_pos)

	if tile_data and tile_data.has_custom_data("damage"):
		var dmg = tile_data.get_custom_data("damage")
		_take_damage(dmg)

func _take_damage(amount: int):
	print("Player terkena damage:", amount)
	# Di sini kamu bisa kurangi HP, mainkan animasi, dsb
