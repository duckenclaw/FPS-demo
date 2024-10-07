extends CharacterBody3D

@onready var firstPersonCamera: Camera3D = $CameraContainer/FirstPersonCamera
@onready var anim_player: AnimationPlayer = $AnimationPlayer

const MAX_HP: int = 100
const SPEED: float = 5.0
const SPRINT_SPEED: float = 7.0
const JUMP_VELOCITY: float = 4.5
const MOUSE_SENSITIVITY: float = 0.05

const DASH_SPEED: float = 15.0
const DASH_DURATION: float = 0.3  # How long the dash lasts
const DASH_COOLDOWN: float = 1.0  # Time between dash recharge

var hp: int
var dash_uses: int = 2
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var is_dashing: bool = false

var is_sprinting: bool = false
var is_crouching: bool = false

# Camera Shake and Walking Sway Variables
@export_category("Camera Shake")
@export var CameraShake_Noise : Noise
@export var CameraShake_NoisePanningSpeed : float = 30
@export var CameraShake_MaxPower : float = 0.15
@export var CameraShake_BlendSpeed : float = 7
@export var CameraShake_ReturnStrength : float = 5
@export var CameraShake_NoiseStrength : float = 0.2
@export var CameraShake_FallingBias : float = 1.0
@export var CameraShake_FallingStrengthFalloff : float = 2.0
@export var CameraShake_FallingMaxStrength : float = 1.0
@export var CameraShake_JumpingStrength : float = 0.2

@export_category("Walking Sway")
@export var WalkingSway_StepsPerSecond : float = 5.0
@export var WalkingSway_MaxSwayDistance : float = 0.05
@export var WalkingSway_MaxSwayHandsHeight : float = -0.005
@export var WalkingSway_MaxSwayCameraHeight : float = 0.05
@export var WalkingSway_BlendSpeed : float = 5
@export var WalkingSway_Bias : float = 0.5

var cameraShake_Position: Vector3
var walkingSway_CurrentValue: float
var timeSinceStarted: float
var lastYVelocity: float

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	hp = MAX_HP
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	_handle_camera_input(event)
	_handle_misc_input()

func _physics_process(delta):
	timeSinceStarted += delta * CameraShake_NoisePanningSpeed
	
	apply_camera_shake(delta)
	handle_jump()
	apply_gravity(delta)
	apply_walking_sway(delta)
	handle_dash_cooldown(delta)

	if is_dashing:
		dash(delta)
	else:
		move(delta)

	move_and_slide()

# Handle camera input
func _handle_camera_input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		firstPersonCamera.rotate_x(deg_to_rad(event.relative.y * MOUSE_SENSITIVITY * -1))
		self.rotate_y(deg_to_rad(event.relative.x * MOUSE_SENSITIVITY * -1))
		
		var camera_rot = firstPersonCamera.rotation_degrees
		camera_rot.x = clamp(camera_rot.x, -70, 70)
		firstPersonCamera.rotation_degrees = camera_rot

# Handle sprinting, crouching, and dash input
func _handle_misc_input():
	if Input.is_action_just_pressed("ui_cancel"):
		toggle_mouse_mode()

	if Input.is_action_pressed("Sprint"):
		is_sprinting = true
	else:
		is_sprinting = false
	
	if Input.is_action_just_pressed("Crouch"):
		toggle_crouch()

	if Input.is_action_just_pressed("Dash") and dash_uses > 0 and not is_dashing:
		start_dash()

# Toggle mouse mode
func toggle_mouse_mode():
	if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# Toggle crouch animation
func toggle_crouch():
	if is_crouching:
		is_crouching = false
		anim_player.play("Uncrouch")
	else:
		is_crouching = true
		anim_player.play("Crouch")

# Start dash
func start_dash():
	is_dashing = true
	dash_timer = DASH_DURATION
	dash_uses -= 1

# Dash movement
func dash(delta: float):
	dash_timer -= delta
	if dash_timer > 0.0:
		var input_dir = Input.get_vector("Left", "Right", "Forwards", "Backwards")
		var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if direction:
			velocity.z = direction.z * DASH_SPEED
			velocity.x = direction.x * DASH_SPEED
	else:
		is_dashing = false

# Normal movement
func move(delta: float):
	var input_dir = Input.get_vector("Left", "Right", "Forwards", "Backwards")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		if is_sprinting:
			velocity.z = direction.z * SPRINT_SPEED
			velocity.x = direction.x * SPRINT_SPEED
		else:
			velocity.z = direction.z * SPEED
			velocity.x = direction.x * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

# Handle dash cooldown
func handle_dash_cooldown(delta: float):
	if dash_uses < 2:
		dash_cooldown_timer -= delta
		if dash_cooldown_timer <= 0.0:
			dash_cooldown_timer = DASH_COOLDOWN
			dash_uses += 1

# Handle jump input
func handle_jump():
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		ImpulseCamera(Vector3.UP, CameraShake_JumpingStrength)

# Apply gravity
func apply_gravity(delta: float):
	if not is_on_floor():
		velocity.y -= gravity * delta
		walkingSway_CurrentValue = max(walkingSway_CurrentValue - delta * WalkingSway_BlendSpeed, 0)
		lastYVelocity = velocity.y
	else:
		if lastYVelocity < -CameraShake_FallingBias:
			ImpulseCamera(Vector3.DOWN, smoothstep(CameraShake_FallingBias, CameraShake_FallingStrengthFalloff + CameraShake_FallingBias, abs(lastYVelocity)) * CameraShake_FallingMaxStrength)

		if velocity.length() > WalkingSway_Bias:
			walkingSway_CurrentValue = min(walkingSway_CurrentValue + delta * WalkingSway_BlendSpeed, 1.0)
		else:
			walkingSway_CurrentValue = max(walkingSway_CurrentValue - delta * WalkingSway_BlendSpeed, 0)
	
	lastYVelocity = velocity.y

# Apply camera shake
func apply_camera_shake(delta: float):
	if cameraShake_Position.length() > 0.0001:
		var noise = (Vector3(CameraShake_Noise.get_noise_1d(timeSinceStarted), CameraShake_Noise.get_noise_1d(timeSinceStarted + 1000), CameraShake_Noise.get_noise_1d(timeSinceStarted + 2000)) * CameraShake_NoiseStrength) * (cameraShake_Position.length() / CameraShake_MaxPower)
		firstPersonCamera.position = firstPersonCamera.position.lerp(cameraShake_Position + noise, float(delta) * CameraShake_BlendSpeed)
		cameraShake_Position = cameraShake_Position.lerp(Vector3.ZERO, delta * CameraShake_ReturnStrength)
	else:
		firstPersonCamera.position = Vector3.ZERO

# Apply walking sway
func apply_walking_sway(delta: float):
	if walkingSway_CurrentValue > 0:
		var stepSpeed: float = delta * WalkingSway_StepsPerSecond
		var stepBounce: float = (EaseInOutSine(-1.0, 1.0, timeSinceStarted * stepSpeed * 2.0 + 0.2) * -1.0) * WalkingSway_MaxSwayHandsHeight
		firstPersonCamera.position.y += (EaseInOutSine(-1.0, 1.0, timeSinceStarted * stepSpeed * 2.0 + 0.2) * -1.0) * WalkingSway_MaxSwayCameraHeight

# Impulse camera for shake effect
func ImpulseCamera(impulseVector: Vector3, impulsePower: float):
	cameraShake_Position += impulseVector * impulsePower
	cameraShake_Position = cameraShake_Position.normalized() * min(cameraShake_Position.length(), CameraShake_MaxPower)

func EaseInOutSine(start: float, end: float, value: float) -> float:
	end -= start
	return -end * 0.5 * (cos(PI * value) - 1.0) + start
