extends MarginContainer

@onready var main_menu_scene = preload("res://scenes/UI/menu.tscn")

signal open_options()
signal unpause()

func _on_options_pressed():
	open_options.emit()


func _on_continue_pressed():
	unpause.emit()


func _on_exit_menu_pressed():
	get_tree().change_scene_to_packed(main_menu_scene)


func _on_exit_desktop_pressed():
	get_tree().quit(0)
