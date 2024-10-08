extends Control

@onready var main_screen = $MainMenu
@onready var options_screen = $OptionsMenu

func _on_main_menu_open_options():
	main_screen.visible = false
	options_screen.visible = true


func _on_options_menu_close_options():
	options_screen.visible = false
	main_screen.visible = true
