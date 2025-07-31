extends Node
class_name EquipmentManager

signal equipment_changed(slot: String, item: Item)
signal stats_updated(stats: Dictionary)

# Equipment slots
var equipped_items: Dictionary = {
	"head": null,
	"body": null, 
	"arms": null,
	"legs": null,
	"left_hand": null,
	"right_hand": null
}

# Cached stats for performance
var total_stats: Dictionary = {}

func _ready():
	_update_stats()

func equip_item(item: Item, slot: String = "") -> bool:
	if not item.can_be_equipped:
		print("Item cannot be equipped: ", item.name)
		return false
	
	# Use item's preferred slot if no slot specified
	if slot == "":
		slot = item.equipment_slot
	
	# Check if item can be equipped to this slot
	if not item.can_equip_to_slot(slot):
		print("Item cannot be equipped to slot ", slot, ": ", item.name)
		return false
	
	# Handle two-handed weapons
	if item.is_two_handed:
		return _equip_two_handed_weapon(item)
	
	# Unequip current item in slot if any
	if equipped_items[slot] != null:
		unequip_item(slot)
	
	# Equip the new item
	equipped_items[slot] = item
	emit_signal("equipment_changed", slot, item)
	_update_stats()
	
	print("Equipped ", item.name, " to ", slot)
	return true

func _equip_two_handed_weapon(weapon: Item) -> bool:
	# Check if both hands are available or if one hand has the same two-handed weapon
	var left_item = equipped_items["left_hand"]
	var right_item = equipped_items["right_hand"]
	
	# If both hands are occupied by different items, can't equip
	if left_item != null and right_item != null and left_item != right_item:
		print("Cannot equip two-handed weapon: both hands occupied")
		return false
	
	# Unequip items in both hands
	if left_item != null:
		unequip_item("left_hand")
	if right_item != null:
		unequip_item("right_hand")
	
	# Equip to both hands
	equipped_items["left_hand"] = weapon
	equipped_items["right_hand"] = weapon
	
	emit_signal("equipment_changed", "left_hand", weapon)
	emit_signal("equipment_changed", "right_hand", weapon)
	_update_stats()
	
	print("Equipped two-handed weapon: ", weapon.name)
	return true

func unequip_item(slot: String) -> Item:
	var item = equipped_items[slot]
	if item == null:
		return null
	
	# Handle two-handed weapons
	if item.is_two_handed:
		equipped_items["left_hand"] = null
		equipped_items["right_hand"] = null
		emit_signal("equipment_changed", "left_hand", null)
		emit_signal("equipment_changed", "right_hand", null)
	else:
		equipped_items[slot] = null
		emit_signal("equipment_changed", slot, null)
	
	_update_stats()
	print("Unequipped ", item.name, " from ", slot)
	return item

func get_equipped_item(slot: String) -> Item:
	return equipped_items.get(slot, null)

func is_slot_occupied(slot: String) -> bool:
	return equipped_items[slot] != null

func get_all_equipped_items() -> Array:
	var items = []
	var added_items = {}  # To avoid duplicating two-handed weapons
	
	for slot in equipped_items:
		var item = equipped_items[slot]
		if item != null and not added_items.has(item):
			items.append(item)
			added_items[item] = true
	
	return items

func _update_stats():
	total_stats = {}
	
	# Get all unique equipped items to avoid double-counting two-handed weapons
	var items = get_all_equipped_items()
	
	# Calculate total bonuses
	for item in items:
		var bonuses = item.get_stat_bonuses()
		for stat in bonuses:
			if total_stats.has(stat):
				total_stats[stat] += bonuses[stat]
			else:
				total_stats[stat] = bonuses[stat]
	
	emit_signal("stats_updated", total_stats)

func get_total_stats() -> Dictionary:
	return total_stats

func get_stat_value(stat_name: String) -> float:
	return total_stats.get(stat_name, 0.0)

func can_equip_item(item: Item, slot: String = "") -> bool:
	if not item.can_be_equipped:
		return false
	
	if slot == "":
		slot = item.equipment_slot
	
	if not item.can_equip_to_slot(slot):
		return false
	
	# Special check for two-handed weapons
	if item.is_two_handed:
		var left_item = equipped_items["left_hand"]
		var right_item = equipped_items["right_hand"]
		
		# Can equip if both hands are free, or if both hands have the same two-handed weapon
		return (left_item == null and right_item == null) or (left_item == right_item)
	
	return true 