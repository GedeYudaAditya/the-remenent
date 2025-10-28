extends ItemBase
class_name WeaponBase

@export var damage: int = 10
@export var cooldown: float = 0.3                 # waktu antar tembakan
@export var cooldown_weapon: float = 0.5          # waktu untuk isi 1 peluru
@export var ammo: int = 5                         # jumlah peluru saat ini (-1 = unlimited)
@export var automatic: bool = false               # true = bisa tahan tombol
@export var auto_reload_on_idle: bool = true      # reload otomatis saat berhenti menembak
@export var reload_idle_delay := 0.8              # waktu tunggu sebelum reload otomatis

# === INTERNAL STATE ===
var _can_attack := true
var _cooldown_timer := 0.0

var _is_reloading := false
var _reload_timer := 0.0
var _max_ammo := 0

var _is_using := false
var _reload_delay_timer := 0.0

func _ready():
	_max_ammo = ammo

func _process(delta):
	# === COOLDOWN ATTACK (tiap tembakan) ===
	if not _can_attack:
		_cooldown_timer -= delta
		if _cooldown_timer <= 0.0:
			_can_attack = true

	# === RELOAD PER PELURU ===
	if _is_reloading:
		_reload_timer -= delta
		if _reload_timer <= 0.0:
			reload_one_bullet()

	# === AUTO RELOAD SAAT IDLE ===
	if auto_reload_on_idle and not _is_using and not _is_reloading and ammo < _max_ammo:
		_reload_delay_timer -= delta
		if _reload_delay_timer <= 0.0:
			start_reload()

func use():
	if not _can_attack or _is_reloading:
		return
	if ammo == 0:
		start_reload()
		return

	_is_using = true
	_reload_delay_timer = reload_idle_delay  # reset delay reload otomatis

	attack()

	if ammo > 0:
		ammo -= 1
		print("%s menyerang dengan damage %d (ammo tersisa: %d)" % [item_name, damage, ammo])

		if ammo == 0:
			start_reload()

	# cooldown antar tembakan
	_can_attack = false
	_cooldown_timer = cooldown

func stop_use():
	# dipanggil saat tombol attack dilepas
	_is_using = false
	_reload_delay_timer = reload_idle_delay

func attack():
	# fungsi virtual — override oleh senjata turunan
	print("%s menyerang dengan damage %d" % [item_name, damage])

# === SISTEM RELOAD PER PELURU ===
func start_reload():
	if _is_reloading or ammo >= _max_ammo or _max_ammo <= 0:
		return
	_is_reloading = true
	_reload_timer = cooldown_weapon
	print("%s mulai reload (%.1f detik per peluru)..." % [item_name, cooldown_weapon])

func reload_one_bullet():
	if ammo < _max_ammo:
		ammo += 1
		print("%s menambahkan 1 peluru. Sekarang: %d/%d" % [item_name, ammo, _max_ammo])
		_reload_timer = cooldown_weapon  # reset timer untuk peluru berikutnya
	else:
		stop_reload()

func stop_reload():
	if _is_reloading:
		_is_reloading = false
		print("%s selesai reload (%d/%d peluru)." % [item_name, ammo, _max_ammo])
