extends Control

@onready var main_screen = $MainPause
@onready var options_screen = $OptionsMenu

signal unpause()

func _on_options_menu_close_options():
	options_screen.visible = false
	main_screen.visible = true


func _on_main_pause_open_options():
	main_screen.visible = false
	options_screen.visible = true


func _on_main_pause_unpause():
	unpause.emit()
