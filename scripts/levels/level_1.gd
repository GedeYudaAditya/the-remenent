extends Node2D

@onready var back_button = $BackButton

func _ready():
	# Atur ukuran background biar nutup layar penuh
	$Background.color = Color(0.1, 0.1, 0.1, 1) # abu-abu gelap
	$Background.size = get_viewport().get_visible_rect().size
	
	# Setup tombol kembali
	back_button.text = "Back to Menu"
	back_button.pressed.connect(_on_back_pressed)

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
