extends Area2D
class_name Bullet

var velocity := Vector2.ZERO

func shoot(direction: Vector2, speed: float):
	velocity = direction.normalized() * speed

func _physics_process(delta):
	global_position += velocity * delta
