extends WeaponBase
class_name PistolWeapon

@export var bullet_scene: PackedScene
@export var shoot_speed := 600.0

func _physics_process(delta):
	if is_held:
		if holder:
			global_position = holder.global_position + hold_offset
		return

	# Gravitasi hanya bekerja kalau tidak dipegang
	velocity.y = min(velocity.y + gravity_force * delta, max_fall_speed)
	move_and_slide()

func attack():
	if not holder:
		return
	
	var bullet = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = global_position

	# arah tembakan mengikuti arah player
	var dir = Vector2.RIGHT if not holder.sprite_2d.flip_h else Vector2.LEFT
	bullet.shoot(dir, shoot_speed)

	print("%s menembak peluru!" % item_name)
