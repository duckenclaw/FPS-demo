extends RigidBody3D

const DAMAGE: int = 25
const SPEED: float = 1.0

var velocity = Vector3.FORWARD

# Called when the node enters the scene tree for the first time.
func _init():
	print("Pew")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	global_transform.origin += velocity * SPEED


func _on_hitbox_area_entered(area):
	if area.is_in_group("enemy"):
		area.take_damage(DAMAGE)
		self.queue_free()

