extends Resource
class_name Item

# Basic Item Stats
@export var name: String = "Unnamed"
@export var description: String = "No description available."
@export var size: Vector2i = Vector2i(1, 1) # Width x Height in grid slots
@export var icon: Texture2D = load("res://icon.png")
@export var model: Mesh = load("res://assets/models/sci-fi-pistol.res")
@export var weight: float = 1.0
@export var price: int = 0
@export var category: String = "generic" # weapon, equipment, consumable, etc.

# Equipment properties (overridden in derived classes)
@export var can_be_equipped: bool = false
@export var equipment_slot: String = "" # "left_hand", "right_hand", "head", "body", "arms", "legs"
@export var is_two_handed: bool = false

# Optional functions for special item behavior
func use_item(player) -> bool:
	# Override in derived items for special behavior when used
	print("Used item: ", name)
	return false

func get_equip_slot() -> String:
	# Return the equipment slot this item can be equipped to
	return equipment_slot

func get_stat_bonuses() -> Dictionary:
	# Override in derived classes to provide stat bonuses
	return {}

func can_equip_to_slot(slot: String) -> bool:
	# Check if this item can be equipped to the given slot
	if not can_be_equipped:
		return false
	
	if is_two_handed:
		return slot == "left_hand" or slot == "right_hand"
	
	return equipment_slot == slot


