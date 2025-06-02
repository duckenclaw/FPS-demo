extends Resource
class_name Item

@export var name: String = "Unnamed"
@export var size: Vector2i = Vector2i(1, 1) # Width x Height in grid slots
@export var icon: Texture2D = load("res://icon.png")
@export var model: Mesh = load("res://assets/models/sci-fi-pistol.res")
@export var description: String = "No description available."

# Optional functions for special item behavior
func use_item(player) -> bool:
	# Override in derived items for special behavior when used
	print("Used item")
	return false

func can_be_equipped() -> bool:
	# Override in derived items if they can be equipped
	return false

func get_equip_slot() -> String:
	# Override in derived items to specify equipment slot
	return ""


