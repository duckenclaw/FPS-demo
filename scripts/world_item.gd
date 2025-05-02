extends Area3D
class_name WorldItem

var item_data: Item
@export var item_resource: Resource
var mesh_instance: MeshInstance3D
var collision_shape: CollisionShape3D

# For interaction highlighting
var is_highlighted = false
var original_material = null
var highlight_material = null

func _ready():
	if item_data == null and item_resource:
		setup_from_item(item_resource)
	
	# Set up interaction
	input_ray_pickable = true
	
	# Create highlight material
	highlight_material = StandardMaterial3D.new()
	highlight_material.albedo_color = Color(1, 1, 0.5, 0.8)  # Yellowish highlight
	highlight_material.emission_enabled = true
	highlight_material.emission = Color(1, 1, 0.5, 0.5)
	highlight_material.emission_energy = 0.5

func setup_from_item(item: Item):
	mesh_instance = $Mesh
	collision_shape = $Collider
	item_data = item
	item_resource = item
	
	# Load the model
	var model = item.model
	
	mesh_instance.mesh = model
	
	# Set up collision shape based on mesh bounds
	var aabb = get_item_aabb()
	collision_shape.shape.size = aabb.size
	collision_shape.position = aabb.position + aabb.size/2

func get_item_aabb() -> AABB:
	# Get bounding box of the model
	if mesh_instance and mesh_instance.mesh:
		return mesh_instance.mesh.get_aabb()
	else:
		# Default size if no mesh
		return AABB(Vector3(-0.5, 0, -0.5), Vector3(1, 1, 1))

func highlight():
	if is_highlighted or original_material == null:
		return
		
	is_highlighted = true
	mesh_instance.set_surface_override_material(0, highlight_material)

func unhighlight():
	if not is_highlighted:
		return
		
	is_highlighted = false
	if original_material:
		mesh_instance.set_surface_override_material(0, original_material)
	else:
		mesh_instance.set_surface_override_material(0, null)

func interact_reaction():
	# Return the item data so it can be added to inventory
	print(name +" item picked up")
	return item_data
