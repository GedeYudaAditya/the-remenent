extends Node

func _ready():
	call_deferred("_goto_menu")

func _goto_menu():
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
