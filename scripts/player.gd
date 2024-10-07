extends CharacterBody3D

@onready var firstPersonCamera = $FirstPersonCamera

const MAX_HP: int = 100
const SPEED:float = 5.0
const SPRINT_SPEED:float = 7.0
const JUMP_VELOCITY:float = 4.5
const MOUSE_SENSITIVITY:float = 0.05

var hp: int

var is_sprinting:bool = false

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	hp = MAX_HP
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	# Camera control
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		firstPersonCamera.rotate_x(deg_to_rad(event.relative.y * MOUSE_SENSITIVITY * -1))
		self.rotate_y(deg_to_rad(event.relative.x * MOUSE_SENSITIVITY * -1))
		
		var camera_rot = firstPersonCamera.rotation_degrees
		camera_rot.x = clamp(camera_rot.x, -70, 70)
		firstPersonCamera.rotation_degrees = camera_rot
	
	# Sprinting
	if Input.is_action_pressed("Dash"):
		is_sprinting = true
	else:
		is_sprinting = false


func _physics_process(delta):
	# Capture/Free mouse
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("Left", "Right", "Forwards", "Backwards")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		if is_sprinting:
			velocity.z = direction.z * SPRINT_SPEED
			velocity.x = direction.x * SPRINT_SPEED
			print(direction)
		else:
			velocity.z = direction.z * SPEED
			velocity.x = direction.x * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
