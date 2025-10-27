extends Control

@onready var button_start: Button = $"CenterContainer/VBoxContainer/Button Start"
@onready var button_option: Button = $"CenterContainer/VBoxContainer/Button Option"
@onready var button_exit: Button = $"CenterContainer/VBoxContainer/Button Exit"

func _ready():
	button_start.pressed.connect(_on_start_pressed)
	button_option.pressed.connect(_on_options_pressed)
	button_exit.pressed.connect(_on_exit_pressed)

func _on_start_pressed():
	print("Start Game") 
	# TODO: ganti ke scene level pertama
	get_tree().change_scene_to_file("res://scenes/levels/level_1.tscn")

func _on_options_pressed():
	print("Open Options")
	# TODO: buka scene/options atau popup

func _on_exit_pressed():
	get_tree().quit()
