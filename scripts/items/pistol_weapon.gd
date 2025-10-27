extends WeaponBase
class_name PistolWeapon

@export var bullet_scene: PackedScene
@export var shoot_speed := 300.0

func _physics_process(delta):
	if is_held:
		if holder:
			# Update posisi senjata relatif terhadap player
			var flipped_offset = hold_offset
			flipped_offset.x *= -1 if holder.sprite_2d.flip_h else 1
			global_position = holder.global_position + flipped_offset

			# === Rotasi senjata berdasarkan arah bidikan ===
			var aim_dir = holder.aim_direction.normalized()
			rotation = aim_dir.angle()

			# === Perbaiki orientasi sprite ===
			# Jangan pakai flip_h di sini, karena rotasi sudah cukup
			# Namun, jika sprite terlihat terbalik (misal menghadap kiri), kita bisa cek rotasinya
			if abs(aim_dir.x) > 0.1:
				$Sprite2D.flip_v = aim_dir.x < 0  # Gunakan flip_v untuk mirror secara vertikal
			else:
				$Sprite2D.flip_v = false
		return

	# Gravitasi hanya aktif kalau senjata tidak dipegang
	velocity.y = min(velocity.y + gravity_force * delta, max_fall_speed)
	move_and_slide()


func attack():
	if not holder:
		return
	
	var bullet = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = global_position

	# arah tembakan mengikuti aim_direction dari holder
	var dir = holder.aim_direction.normalized()
	bullet.shoot(dir, shoot_speed)

	print("%s menembak peluru ke arah %s!" % [item_name, str(dir)])
