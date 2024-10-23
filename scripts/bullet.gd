extends RigidBody3D

const DAMAGE: int = 25
const SPEED: float = 10.0

var velocity = Vector3.FORWARD

# Called when the node enters the scene tree for the first time.
func _init():
	print("Pew")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	position += transform.basis * Vector3(0, 0, -SPEED) * delta


func _on_hitbox_area_entered(area):
	if area.is_in_group("enemy"):
		area.take_damage(DAMAGE)
		self.queue_free()



func _on_hitbox_body_entered(body):
	self.queue_free()
