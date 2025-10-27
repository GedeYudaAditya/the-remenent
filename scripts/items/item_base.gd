# ItemBase.gd
extends CharacterBody2D
class_name ItemBase

@export var item_name: String = ""
@export var icon: Texture2D
@export var can_throw: bool = false  # plant = true, lainnya = false
@export var gravity_force := 400.0
@export var max_fall_speed := 300.0
@export var hold_offset := Vector2(0, -5)

var is_held := false
var holder: Node = null

func pick_up(by: Node):
	is_held = true
	holder = by
	if has_node("PickupArea/CollisionShape2D"):
		$PickupArea/CollisionShape2D.disabled = true

func drop(pos: Vector2, throw_force := Vector2.ZERO):
	is_held = false
	holder = null
	global_position = pos
	if has_node("PickupArea/CollisionShape2D"):
		$PickupArea/CollisionShape2D.disabled = false
