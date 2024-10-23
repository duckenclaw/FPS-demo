extends Control

@onready var health_bar: ProgressBar = $Margins/Stats/HealthBar
@onready var health_label: Label = $Margins/Stats/HealthBar/Margins/Health

@onready var dash_bar: ProgressBar = $Margins/Stats/DashBar
@onready var dash_label: Label = $Margins/Stats/DashBar/Margins/DashCharges

@onready var pause_menu: Control = $PauseMenu

var max_health: int = 100

func update_health(health):
	health_bar.value = health
	health_label.text = str(health) + "/" + str(max_health)
	
func update_dash(dashes):
	dash_bar.value = dashes
	dash_label.text = str(dashes)
	
func toggle_pause():
	toggle_mouse_mode()
	if Engine.time_scale == 0:
		Engine.time_scale = 1
		print("unpaused")
		pause_menu.visible = false
	else:
		Engine.time_scale = 0
		print("paused")
		pause_menu.visible = true

func toggle_mouse_mode():
	if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_pause_menu_unpause():
	toggle_pause()
