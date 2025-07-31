extends Item
class_name WeaponItem

enum WeaponType {
	MELEE,
	RANGED
}

# Weapon-specific properties
@export var weapon_type: WeaponType = WeaponType.MELEE
@export var damage: float = 10.0

# Melee weapon properties
@export var attack_speed: float = 1.0

# Ranged weapon properties  
@export var accuracy: float = 1.0
@export var rpm: float = 600.0  # Rounds per minute
@export var magazine_size: int = 30
@export var reload_time: float = 2.0
@export var is_automatic: bool = false

func _init():
	category = "weapon"
	can_be_equipped = true
	# Default to right hand for one-handed weapons
	if not is_two_handed:
		equipment_slot = "right_hand"

func get_stat_bonuses() -> Dictionary:
	var bonuses = {}
	bonuses["damage"] = damage
	bonuses["attack_speed"] = attack_speed
	
	if weapon_type == WeaponType.RANGED:
		bonuses["accuracy"] = accuracy
		bonuses["rpm"] = rpm 
		bonuses["magazine_size"] = magazine_size
		bonuses["reload_time"] = reload_time
		bonuses["is_automatic"] = is_automatic
	
	return bonuses

func get_weapon_type_string() -> String:
	match weapon_type:
		WeaponType.MELEE:
			return "Melee"
		WeaponType.RANGED:
			return "Ranged"
		_:
			return "Unknown" 