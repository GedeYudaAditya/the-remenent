extends CharacterBody2D
@onready var sprite_2d: AnimatedSprite2D = $Sprite2D

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

# === RUNTIME VARIABLES ===
var held_item: Node = null
var was_on_floor := true
var jump_time := 0.0
var hold_time := 0.0
var is_looking_back := false
var look_back_timer := 0.0
var aim_direction := Vector2.RIGHT  # default arah tembak


func _physics_process(delta):
	var direction := Input.get_axis("left", "right")
	var looking_up := Input.is_action_pressed("up")
	var looking_down := Input.is_action_pressed("down")

	# === GERAK HORIZONTAL ===
	if direction != 0:
		velocity.x = move_toward(velocity.x, direction * speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)

	# === GRAVITASI & LOMPAT ===
	if is_on_floor():
		jump_time = 0.0
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_force
			sprite_2d.play("jump")
	else:
		if Input.is_action_pressed("jump") and jump_time < max_jump_time and velocity.y < 0:
			velocity.y += low_gravity * delta
			jump_time += delta
		else:
			velocity.y += gravity * delta

	move_and_slide()

	# === ANIMASI ===
	if not is_on_floor():
		# Saat di udara
		if looking_down:
			sprite_2d.play("look_down") # nanti bisa untuk shoot down
		elif looking_up:
			sprite_2d.play("jump_look_up")
		else:
			sprite_2d.play("jump")

	else:
		# Saat di tanah
		if looking_up:
			if abs(direction) > 0:
				sprite_2d.play("run_look_up")
			else:
				sprite_2d.play("look_up")

		# --- LOOK BACK: hanya aktif saat tombol down baru ditekan ---
		elif Input.is_action_just_pressed("down"):
			is_looking_back = true
			look_back_timer = 0.7
			sprite_2d.play("look_back")

		elif is_looking_back:
			# Batalkan look_back jika tombol dilepas / bergerak / loncat
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

		# --- Normal movement animation ---
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
	
	# Arah aim tergantung kondisi player
	if not is_on_floor() and Input.is_action_pressed("down"):
		aim_direction = Vector2.DOWN
	elif Input.is_action_pressed("up"):
		aim_direction = Vector2.UP
	elif sprite_2d.flip_h:
		aim_direction = Vector2.LEFT
	else:
		aim_direction = Vector2.RIGHT

	# === WEAPON USAGE ===
	if held_item and held_item is WeaponBase:
		var weapon = held_item as WeaponBase
		if weapon.automatic:
			if Input.is_action_pressed("attack"):
				weapon.use()
		else:
			if Input.is_action_just_pressed("attack"):
				weapon.use()



# =======================================
# === ITEM SYSTEM ===
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
			# Jika menekan UP → lempar vertikal ke atas (90°)
			dir = Vector2(0, -1)
		else:
			# Lempar ke arah depan dengan sudut 60 derajat
			var base_dir = Vector2.RIGHT if not sprite_2d.flip_h else Vector2.LEFT
			var angle_radians = deg_to_rad(throw_angle)
			dir = base_dir.rotated(-angle_radians if not sprite_2d.flip_h else angle_radians)

		# Lempar item
		held_item.drop(global_position + Vector2(0, -10), dir.normalized() * force)

		# Reset
		held_item = null
		hold_time = 0.0
