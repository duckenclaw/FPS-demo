extends Control
class_name Inventory

signal item_dropped(item, world_position)

# Grid settings
@export var grid_columns = 6
@export var grid_rows = 5
@export var grid_cell_size = 64
@export var grid_padding = 5

# Inventory data
var inventory_items = []  # Array of InventoryItem instances
var grid_positions = {}   # Dictionary mapping grid positions to items
var dragged_item = null
var drag_offset = Vector2.ZERO
var item_rotation_in_progress = false

# References
@onready var grid_container = $Margins/GridContainer
@onready var drag_preview = $Margins/DragPreview

func _ready():
	# Initialize the inventory grid
	setup_grid()
	drag_preview.visible = false
	
	# Connect to input events for drag handling
	get_viewport().connect("gui_focus_changed", Callable(self, "_on_gui_focus_changed"))

func setup_grid():
	# Configure the grid container
	grid_container.columns = grid_columns
	
	# Create empty slots
	for i in range(grid_columns * grid_rows):
		var slot = create_inventory_slot()
		grid_container.add_child(slot)

func create_inventory_slot():
	var slot = TextureRect.new()
	slot.name = "Slot"
	slot.custom_minimum_size = Vector2(grid_cell_size, grid_cell_size)
	slot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	slot.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	slot.texture = preload("res://assets/images/inventory_slot.png")
	slot.set_meta("grid_position", Vector2i(grid_container.get_child_count() % grid_columns, grid_container.get_child_count() / grid_columns))
	
	# Add a script if needed for hover effects
	# var script = load("res://scripts/inventory_slot.gd")
	# slot.set_script(script)
	
	return slot

func _input(event):
	if not visible or dragged_item == null:
		return
		
	if event is InputEventMouseMotion:
		update_drag_position(event.position)
		
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			drop_item(event.position)
			
	# Handle item rotation
	if event.is_action_pressed("Reload") and dragged_item != null:
		rotate_dragged_item()

func rotate_dragged_item():
	if dragged_item == null or item_rotation_in_progress:
		return
		
	item_rotation_in_progress = true
	
	# Swap width and height
	var item_size = dragged_item.get_item().size
	dragged_item.get_item().size = Vector2i(item_size.y, item_size.x)
	dragged_item.rotate_item(true)
	
	# Update the visual representation
	dragged_item.update_texture(false)
	
	item_rotation_in_progress = false

func update_drag_position(position):
	if dragged_item:
		drag_preview.global_position = position - drag_offset

func start_drag(item, start_position):
	if dragged_item != null:
		print("dragged_item != null")
		return
		
	dragged_item = item
	print(dragged_item.name)
	drag_offset = start_position - item.global_position
	
	# Remove from grid and add to preview
	var grid_pos = item.grid_position
	var item_size = item.get_item().size
	
	# Clear grid positions
	for x in range(item_size.x):
		for y in range(item_size.y):
			var pos = Vector2i(grid_pos.x + x, grid_pos.y + y)
			grid_positions.erase(pos)
	
	# Set up drag preview
	drag_preview.add_child(item)
	item.position = Vector2.ZERO
	update_drag_position(get_global_mouse_position())
	drag_preview.visible = true

func drop_item(drop_position):
	if dragged_item == null:
		return
		
	# Remove from drag preview
	drag_preview.remove_child(dragged_item)
	drag_preview.visible = false
	
	# Check if dropping on grid
	var drop_grid_pos = get_grid_position_at(drop_position)
	
	if drop_grid_pos != null and can_place_item_at(dragged_item.get_item(), drop_grid_pos):
		# Place in inventory
		place_item(dragged_item, drop_grid_pos)
	else:
		# Drop in world
		emit_signal("item_dropped", dragged_item.get_item(), Vector3.ZERO)  # Player will provide position
		inventory_items.erase(dragged_item)
		dragged_item.queue_free()
		
	dragged_item = null

func get_grid_position_at(screen_position):
	# Convert screen position to grid position
	var local_pos = grid_container.get_local_mouse_position()
	
	# Check if position is within grid bounds
	if local_pos.x < 0 or local_pos.y < 0 or local_pos.x > grid_container.size.x or local_pos.y > grid_container.size.y:
		return null
		
	var grid_x = int(local_pos.x / (grid_cell_size + grid_padding))
	var grid_y = int(local_pos.y / (grid_cell_size + grid_padding))
	
	if grid_x >= grid_columns:
		return null
		
	return Vector2i(grid_x, grid_y)

func can_place_item_at(item, grid_position):
	var item_size = item.size
	
	# Check if all required slots are available
	for x in range(item_size.x):
		for y in range(item_size.y):
			var check_pos = Vector2i(grid_position.x + x, grid_position.y + y)
			
			# Check if position is within grid
			if check_pos.x >= grid_columns or check_pos.y >= 5:  # Assuming 5 rows
				return false
				
			# Check if position is already occupied
			if grid_positions.has(check_pos):
				return false
				
	return true

func place_item(inv_item, grid_position):
	var item = inv_item.get_item()
	inv_item.grid_position = grid_position
	
	# Update grid positions
	for x in range(item.size.x):
		for y in range(item.size.y):
			var pos = Vector2i(grid_position.x + x, grid_position.y + y)
			grid_positions[pos] = inv_item
	
	# Add to grid container
	grid_container.add_child(inv_item)
	
	print(grid_position)
	
	# Position item
	var slot_pos = grid_to_pixel(grid_position)
	inv_item.position = slot_pos

func grid_to_pixel(grid_pos):
	return Vector2(grid_pos.x * (grid_cell_size + grid_padding), 
				   grid_pos.y * (grid_cell_size + grid_padding))

func add_item(item):
	# Try to find a position for the item
	var position = find_position_for_item(item)
	print(position)
	if position == null:
		return false  # Inventory full
		
	# Create inventory item representation
	var inv_item = create_inventory_item(item, position)
	inventory_items.append(inv_item)
	
	# Place in inventory
	place_item(inv_item, position)
	
	return true

func create_inventory_item(item, grid_position):
	var inv_item = preload("res://scripts/ui/inventory_item.gd").new()
	inv_item.setup(item, grid_position, grid_cell_size)
	inv_item.connect("drag_started", Callable(self, "start_drag"))
	return inv_item

func find_position_for_item(item):
	# Try to find a free position for the item
	for y in range(grid_rows):  # 5 rows
		for x in range(grid_columns):
			var pos = Vector2i(x, y)
			if can_place_item_at(item, pos):
				return pos
				
	return null  # No space found

func toggle():
	visible = !visible
	drag_preview.visible = false
	dragged_item = null
	
func update_grid():
	for inventory_item in inventory_items:
		var slot_pos = grid_to_pixel(inventory_item.grid_position)
		inventory_item.position = slot_pos
