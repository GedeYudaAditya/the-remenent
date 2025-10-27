extends CharacterBody2D
class_name Bullet

@export var speed := 600.0
var direction := Vector2.ZERO

func _ready():
	# Ketika peluru menabrak sesuatu
	connect("body_entered", Callable(self, "_on_body_entered"))

func shoot(dir: Vector2):
	direction = dir.normalized()

func _physics_process(delta):
	var collision = move_and_collide(direction * speed * delta)
	if collision:
		var body = collision.get_collider()
		if body.is_in_group("enemy") and body.has_method("take_damage"):
			body.take_damage(10)
		queue_free()


func _on_body_entered(body):
	# Jika mengenai lantai atau enemy
	if body.is_in_group("ground") or body.is_in_group("enemy"):
		queue_free()  # hapus peluru

		# Jika musuh, bisa tambahkan damage nanti
		if body.is_in_group("enemy") and body.has_method("take_damage"):
			body.take_damage(10)
