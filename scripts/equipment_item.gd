extends Item
class_name EquipmentItem

enum EquipmentType {
	HEAD,
	BODY, 
	ARMS,
	LEGS
}

enum ArmorType {
	NONE,
	LIGHT,
	MEDIUM,
	HEAVY
}

# Equipment-specific properties
@export var equipment_type: EquipmentType = EquipmentType.BODY
@export var armor_type: ArmorType = ArmorType.NONE
@export var defense: int = 0
@export var additional_stats: Dictionary = {} # For custom stat bonuses

func _init():
	category = "equipment"
	can_be_equipped = true
	_set_equipment_slot()

func _set_equipment_slot():
	match equipment_type:
		EquipmentType.HEAD:
			equipment_slot = "head"
		EquipmentType.BODY:
			equipment_slot = "body"
		EquipmentType.ARMS:
			equipment_slot = "arms"
		EquipmentType.LEGS:
			equipment_slot = "legs"

func get_stat_bonuses() -> Dictionary:
	var bonuses = additional_stats.duplicate()
	bonuses["defense"] = defense
	return bonuses

func get_equipment_type_string() -> String:
	match equipment_type:
		EquipmentType.HEAD:
			return "Head"
		EquipmentType.BODY:
			return "Body"
		EquipmentType.ARMS:
			return "Arms"
		EquipmentType.LEGS:
			return "Legs"
		_:
			return "Unknown"

func get_armor_type_string() -> String:
	match armor_type:
		ArmorType.NONE:
			return "None"
		ArmorType.LIGHT:
			return "Light"
		ArmorType.MEDIUM:
			return "Medium"
		ArmorType.HEAVY:
			return "Heavy"
		_:
			return "Unknown" 