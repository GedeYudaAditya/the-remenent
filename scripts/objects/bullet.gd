extends Area2D
class_name Bullet

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

@export var recoil_angle := 2.0      # derajat maksimum penyimpangan (recoil)
@export var max_range := 80.0       # jarak maksimum peluru
@export var damage := 10

var velocity := Vector2.ZERO
var has_hit := false
var start_position := Vector2.ZERO

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))

func shoot(direction: Vector2, shoot_speed: int):
	var recoil_radians = deg_to_rad(randf_range(-recoil_angle, recoil_angle))
	var final_dir = direction.rotated(recoil_radians).normalized()

	velocity = final_dir * shoot_speed
	rotation = final_dir.angle()
	start_position = global_position

	if anim.sprite_frames.has_animation("shoot"):
		anim.play("shoot")

func _physics_process(delta):
	if has_hit:
		return

	global_position += velocity * delta
	rotation = velocity.angle()

	# 🔸 Cek jarak tempuh
	if global_position.distance_to(start_position) > max_range:
		_on_max_range_reached()

func _on_body_entered(body):
	if has_hit:
		return
	has_hit = true

	if collision:
		collision.disabled = true
	velocity = Vector2.ZERO

	if body.is_in_group("enemy"):
		_play_hit_animation("hit_enemy")
		if body.has_method("take_damage"):
			body.take_damage(damage)
	elif body.is_in_group("ground"):
		_play_hit_animation("hit_ground")

func _on_max_range_reached():
	if has_hit:
		return
	has_hit = true

	if collision:
		collision.disabled = true
	velocity = Vector2.ZERO

	# 🔸 Mainkan animasi berbeda kalau peluru menghilang di udara
	_play_hit_animation("disappear")

func _play_hit_animation(anim_name: String):
	if anim.sprite_frames.has_animation(anim_name):
		anim.play(anim_name)
	else:
		queue_free()

	if not anim.is_connected("animation_finished", Callable(self, "_on_anim_finished")):
		anim.connect("animation_finished", Callable(self, "_on_anim_finished"))

func _on_anim_finished():
	queue_free()
