extends Control

@onready var test_scene = preload("res://scenes/qasmoke.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _on_start_pressed():
	get_tree().change_scene_to_packed(test_scene)


func _on_options_pressed():
	pass # Replace with function body.


func _on_exit_pressed():
	get_tree().quit()
