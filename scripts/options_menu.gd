extends MarginContainer

signal close_options()

func _on_exit_pressed():
	close_options.emit()
