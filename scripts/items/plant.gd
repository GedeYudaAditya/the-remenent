# PlantItem.gd
extends ItemBase

@export var plant_health := 100
@onready var sprite_2d: AnimatedSprite2D = $Sprite2D

#var velocity := Vector2.ZERO

func _physics_process(delta):
	if is_held:
		if holder:
			global_position = holder.global_position + hold_offset
		return

	# Gravitasi hanya bekerja kalau tidak dipegang
	velocity.y = min(velocity.y + gravity_force * delta, max_fall_speed)
	move_and_slide()

func take_damage(amount: int):
	plant_health -= amount
	if plant_health <= 0:
		die()

func die():
	queue_free()

func pick_up(by: Node):
	super.pick_up(by) # panggil versi ItemBase
	$PickupArea/CollisionShape2D.disabled = true

func drop(pos: Vector2, throw_force := Vector2.ZERO):
	super.drop(pos, throw_force)
	$PickupArea/CollisionShape2D.disabled = false

	if throw_force.length() > 0:
		velocity = throw_force
