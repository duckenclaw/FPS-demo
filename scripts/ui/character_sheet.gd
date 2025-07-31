extends Control
class_name CharacterSheet

signal item_equipped(item: Item, slot: String)
signal item_unequipped(item: Item, slot: String)

@onready var equipment_manager: EquipmentManager
@onready var inventory: Inventory

# Equipment slot references
var equipment_slots: Dictionary = {}
var slot_positions: Dictionary = {
	"head": Vector2(100, 50),
	"body": Vector2(100, 150),
	"arms": Vector2(100, 250),
	"legs": Vector2(100, 350),
	"left_hand": Vector2(50, 200),
	"right_hand": Vector2(150, 200)
}

# UI References
@onready var stats_panel = $StatsPanel
@onready var stats_label = $StatsPanel/StatsLabel
@onready var equipment_panel = $EquipmentPanel

var dragged_item: InventoryItem = null
var drag_offset: Vector2 = Vector2.ZERO

func _ready():
	# Find the equipment manager and inventory
	equipment_manager = get_node("../EquipmentManager")
	inventory = get_node("../Inventory")
	
	if equipment_manager:
		equipment_manager.connect("equipment_changed", Callable(self, "_on_equipment_changed"))
		equipment_manager.connect("stats_updated", Callable(self, "_on_stats_updated"))
	
	if inventory:
		inventory.connect("item_dropped", Callable(self, "_on_inventory_item_dropped"))
	
	_setup_equipment_slots()
	_update_stats_display()

func _setup_equipment_slots():
	# Create visual equipment slots
	for slot_name in slot_positions:
		var slot_control = _create_equipment_slot(slot_name)
		equipment_panel.add_child(slot_control)
		equipment_slots[slot_name] = slot_control

func _create_equipment_slot(slot_name: String) -> Control:
	var slot = Control.new()
	slot.name = slot_name + "_slot"
	slot.custom_minimum_size = Vector2(64, 64)
	slot.position = slot_positions[slot_name]
	
	# Create background
	var background = TextureRect.new()
	background.custom_minimum_size = Vector2(64, 64)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	background.texture = preload("res://assets/images/inventory_slot.png")
	slot.add_child(background)
	
	# Create label
	var label = Label.new()
	label.text = slot_name.replace("_", " ").capitalize()
	label.position = Vector2(0, 70)
	label.custom_minimum_size = Vector2(64, 20)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slot.add_child(label)
	
	# Set up drag and drop
	slot.set_meta("slot_name", slot_name)
	
	return slot

func _input(event):
	if not visible:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_handle_slot_click(event.position)
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_handle_slot_right_click(event.position)

func _handle_slot_click(position: Vector2):
	# Check if clicking on an equipment slot
	for slot_name in equipment_slots:
		var slot_control = equipment_slots[slot_name]
		var slot_rect = Rect2(slot_control.global_position, slot_control.size)
		
		if slot_rect.has_point(position):
			var equipped_item = equipment_manager.get_equipped_item(slot_name)
			if equipped_item:
				_try_unequip_item(slot_name)
			break

func _handle_slot_right_click(position: Vector2):
	# Right-click for context menu or alternative actions
	for slot_name in equipment_slots:
		var slot_control = equipment_slots[slot_name]
		var slot_rect = Rect2(slot_control.global_position, slot_control.size)
		
		if slot_rect.has_point(position):
			_show_slot_context_menu(slot_name, position)
			break

func _try_unequip_item(slot_name: String):
	var item = equipment_manager.unequip_item(slot_name)
	if item and inventory:
		# Try to add back to inventory
		if not inventory.add_item(item):
			# If inventory is full, re-equip the item
			equipment_manager.equip_item(item, slot_name)
			print("Cannot unequip item: inventory full")

func _show_slot_context_menu(slot_name: String, position: Vector2):
	# TODO: Implement context menu for equipment slots
	print("Context menu for slot: ", slot_name)

func _on_equipment_changed(slot: String, item: Item):
	_update_equipment_slot_display(slot, item)

func _update_equipment_slot_display(slot_name: String, item: Item):
	var slot_control = equipment_slots.get(slot_name)
	if not slot_control:
		return
	
	# Remove existing item display
	var existing_item = slot_control.get_node_or_null("EquippedItem")
	if existing_item:
		existing_item.queue_free()
	
	# Add new item display if item exists
	if item:
		var item_display = TextureRect.new()
		item_display.name = "EquippedItem"
		item_display.texture = item.icon
		item_display.custom_minimum_size = Vector2(64, 64)
		item_display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		item_display.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		item_display.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot_control.add_child(item_display)

func _on_stats_updated(stats: Dictionary):
	_update_stats_display()

func _update_stats_display():
	if not stats_label:
		return
	
	var stats = equipment_manager.get_total_stats()
	var stats_text = "Character Stats:\n"
	
	for stat_name in stats:
		stats_text += stat_name.capitalize() + ": " + str(stats[stat_name]) + "\n"
	
	if stats.is_empty():
		stats_text += "No equipment bonuses"
	
	stats_label.text = stats_text

func _on_inventory_item_dropped(item: Item, world_position: Vector3):
	# Check if item was dropped on character sheet
	if not visible:
		return
	
	var mouse_pos = get_global_mouse_position()
	
	# Check if dropped on an equipment slot
	for slot_name in equipment_slots:
		var slot_control = equipment_slots[slot_name]
		var slot_rect = Rect2(slot_control.global_position, slot_control.size)
		
		if slot_rect.has_point(mouse_pos):
			if equipment_manager.can_equip_item(item, slot_name):
				equipment_manager.equip_item(item, slot_name)
				emit_signal("item_equipped", item, slot_name)
			else:
				print("Cannot equip ", item.name, " to ", slot_name)
			break

func toggle():
	visible = !visible
	if visible:
		_update_stats_display()
		_update_all_equipment_displays()

func _update_all_equipment_displays():
	for slot_name in equipment_slots:
		var item = equipment_manager.get_equipped_item(slot_name)
		_update_equipment_slot_display(slot_name, item) 