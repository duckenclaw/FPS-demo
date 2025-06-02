extends MarginContainer

signal close_options()

func _on_back_pressed():
	close_options.emit()
