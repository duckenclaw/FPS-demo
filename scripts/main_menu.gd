extends MarginContainer

@onready var start_scene = preload("res://scenes/qasmoke.tscn")

signal open_options()

func _on_start_pressed():
	get_tree().change_scene_to_packed(start_scene)


func _on_options_pressed():
	open_options.emit()


func _on_exit_pressed():
	get_tree().quit()
