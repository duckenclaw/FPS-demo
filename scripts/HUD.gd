extends Control

@onready var health_bar: ProgressBar = $Margins/Stats/HealthBar
@onready var health_label: Label = $Margins/Stats/HealthBar/Margins/Health

@onready var dash_bar: ProgressBar = $Margins/Stats/DashBar
@onready var dash_label: Label = $Margins/Stats/DashBar/Margins/DashCharges

@onready var pause_menu: Control = $PauseMenu
@onready var inventory: Control = $Inventory
@onready var crosshair: TextureRect = $Margins/CrosshairContainer/CrosshairImage

signal inventory_toggled(visible)
signal inventory_item_dropped(item, position)

var max_health: int = 100

func _ready():
	inventory.connect("item_dropped", Callable(self, "_on_inventory_item_dropped"))
	inventory.visible = false
	
	# Ensure crosshair is visible
	crosshair.visible = true

func update_health(health):
	health_bar.value = health
	health_label.text = str(health) + "/" + str(max_health)
	
func update_dash(dashes):
	dash_bar.value = dashes
	dash_label.text = str(dashes)
	
func toggle_pause():
	if not inventory.visible:
		if Engine.time_scale == 0:
			toggle_mouse_mode()
			Engine.time_scale = 1
			print("unpaused")
			pause_menu.visible = false
		else:
			toggle_mouse_mode()
			Engine.time_scale = 0
			print("paused")
			pause_menu.visible = true

func toggle_inventory():
	inventory.visible = !inventory.visible
	inventory.update_grid()
	
	# Only capture mouse when inventory is open
	if inventory.visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		Engine.time_scale = 0  # Pause the game
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		Engine.time_scale = 1  # Unpause the game
	
	emit_signal("inventory_toggled", inventory.visible)

func toggle_mouse_mode():
	if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_pause_menu_unpause():
	toggle_pause()

func _on_inventory_item_dropped(item, position):
	emit_signal("inventory_item_dropped", item, position)

func add_item_to_inventory(item):
	return inventory.add_item(item)
	
