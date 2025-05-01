extends Control
class_name InventoryItem

signal drag_started(item, position)

var item_data: Item
var grid_position: Vector2i
var cell_size: int

func _ready():
	# Add mouse input handling
	mouse_filter = Control.MOUSE_FILTER_PASS
	set_process_input(true)

func setup(item: Item, position: Vector2i, size: int):
	item_data = item
	grid_position = position
	cell_size = size
	
	# Set the control size based on item dimensions
	custom_minimum_size = Vector2(item.size.x * cell_size, item.size.y * cell_size)
	update_texture()

func update_texture():
	# Remove any existing texture
	for child in get_children():
		child.queue_free()
	
	# Create the texture container
	var texture_rect = TextureRect.new()
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.texture = item_data.icon
	texture_rect.size = Vector2(item_data.size.x * cell_size, item_data.size.y * cell_size)
	add_child(texture_rect)
	
	# Add item name label
	var label = Label.new()
	label.text = item_data.name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	label.size = Vector2(item_data.size.x * cell_size, item_data.size.y * cell_size)
	add_child(label)

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var rect = Rect2(global_position, custom_minimum_size)
			if rect.has_point(event.global_position):
				emit_signal("drag_started", self, event.global_position)
				get_viewport().set_input_as_handled()

func get_item() -> Item:
	return item_data 
