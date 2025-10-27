extends ItemBase
class_name WeaponBase

@export var damage: int = 10
@export var cooldown: float = 0.3
@export var ammo: int = -1  # -1 = unlimited
@export var automatic: bool = false  # true = bisa tahan tombol

var _can_attack := true
var _cooldown_timer := 0.0

func _process(delta):
	# Handle cooldown
	if not _can_attack:
		_cooldown_timer -= delta
		if _cooldown_timer <= 0.0:
			_can_attack = true

func use():
	# dipanggil saat player menekan tombol attack
	if not _can_attack:
		return
	if ammo == 0:
		return # tidak ada peluru

	attack()

	if ammo > 0:
		ammo -= 1

	# mulai cooldown
	_can_attack = false
	_cooldown_timer = cooldown

func attack():
	# ini fungsi virtual — override di turunan seperti GunWeapon atau SwordWeapon
	print("%s menyerang dengan damage %d" % [item_name, damage])
