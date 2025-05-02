extends CharacterBody3D

@onready var weaponsCamera: Camera3D = $HUD/SubViewportContainer/SubViewport/SubViewportCamera
@onready var firstPersonCamera: Camera3D = $CameraContainer/FirstPersonCamera
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var primary_weapon: Node3D = $CameraContainer/FirstPersonCamera/WeaponPivot/Sword
@onready var primary_weapon_hitbox: Node3D = $CameraContainer/FirstPersonCamera/WeaponPivot/Sword/Hitbox
@onready var secondary_weapon: Node3D = $CameraContainer/FirstPersonCamera/WeaponPivot/Gun
@onready var secondary_weapon_gunpoint: Node3D = $CameraContainer/FirstPersonCamera/WeaponPivot/Gun/Gunpoint
@onready var crosshair_raycast: RayCast3D = $CameraContainer/FirstPersonCamera/WeaponPivot/CrosshairRaycast
@onready var hud: Control = $HUD/SubViewportContainer/SubViewport/HudUI
@onready var item_detector_raycast: RayCast3D = $CameraContainer/FirstPersonCamera/RayCast3D

@onready var projectile_scene = preload("res://scenes/bullet.tscn")
@onready var world_item_scene = preload("res://scenes/world_items/world_item.tscn")

const MAX_HP: int = 100
const SPEED: float = 5.0
const SPRINT_SPEED: float = 7.0
const JUMP_VELOCITY: float = 4.5
const HIGHJUMP_VELOCITY: float = 6.5
const DOUBLE_JUMP_VELOCITY: float = 4.0
const GLIDE_FALL_SPEED: float = 2.0
const HIGHJUMP_TIME: float = 0.5
const CHARGE_SPEED: float = 15.0
const MOUSE_SENSITIVITY: float = 0.05
const MELEE_DAMAGE: int = 75
const RANGED_DAMAGE: int = 25

const DASH_SPEED: float = 15.0
const DASH_DURATION: float = 0.3  # How long the dash lasts
const DASH_COOLDOWN: float = 1.0  # Time between dash recharge

# Input Buffer System
const INPUT_BUFFER_TIME: float = 0.5  # Time window for input buffer in seconds
const CHARGE_BUFFER_TIME: float = 0.3  # Time window for charge moves

var hp: int
var dash_uses: int = 2
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var jump_hold_timer: float = 0.0
var can_double_jump: bool = true
var is_charging: bool = false
var charge_direction: Vector3 = Vector3.ZERO
var is_gliding: bool = false
var is_holding_jump: bool = false

var input_buffer: Array = []
var input_times: Array = []
var last_direction: String = ""
var direction_change_time: float = 0.0

var is_dashing: bool = false
var is_sprinting: bool = false
var is_crouching: bool = false
var is_blocking: bool = false
var is_shooting: bool = false

signal blocked

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

# Item interaction
var highlighted_item = null

func _ready():
	hp = MAX_HP
	hud.max_health = MAX_HP
	hud.update_health(hp)
	hud.update_dash(dash_uses)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Connect to inventory signals
	hud.connect("inventory_item_dropped", Callable(self, "_on_inventory_item_dropped"))

func _input(event):
	handle_camera_input(event)
	handle_movement_input(event)
	handle_misc_input()

func _process(delta):
	weaponsCamera.global_transform = (firstPersonCamera.global_transform)

func _physics_process(delta):
	timeSinceStarted += delta * CameraShake_NoisePanningSpeed
	
	apply_camera_shake(delta)
	handle_jump()
	
	if is_on_floor():
		can_double_jump = true
		is_gliding = false
	
	apply_gravity(delta)
	apply_walking_sway(delta)
	handle_dash_cooldown(delta)

	if is_dashing:
		dash(delta)
	else:
		move(delta)

	move_and_slide()
	
	# Update item detection
	update_item_detection()

# Handle camera input
func handle_camera_input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		firstPersonCamera.rotate_x(deg_to_rad(event.relative.y * MOUSE_SENSITIVITY * -1))
		self.rotate_y(deg_to_rad(event.relative.x * MOUSE_SENSITIVITY * -1))
		
		var camera_rot = firstPersonCamera.rotation_degrees
		camera_rot.x = clamp(camera_rot.x, -70, 70)
		firstPersonCamera.rotation_degrees = camera_rot

# Handle movement input for input buffer
func handle_movement_input(event):
	if event.is_action_pressed("Forwards"):
		add_to_input_buffer("W")
		last_direction = "forward"
		direction_change_time = Time.get_ticks_msec() / 1000.0
	elif event.is_action_pressed("Backwards"):
		add_to_input_buffer("S")
		last_direction = "backward"
		direction_change_time = Time.get_ticks_msec() / 1000.0
	elif event.is_action_pressed("Left"):
		add_to_input_buffer("A")
		last_direction = "left"
		direction_change_time = Time.get_ticks_msec() / 1000.0
	elif event.is_action_pressed("Right"):
		add_to_input_buffer("D")
		last_direction = "right"
		direction_change_time = Time.get_ticks_msec() / 1000.0

# Handle sprinting, crouching, and dash input
func handle_misc_input():
	if Input.is_action_pressed("Inventory"):
		hud.toggle_inventory()
	
	# Handle item interaction
	if Input.is_action_pressed("Interact") and Engine.time_scale != 0:
		interact_with_item()
	
	if Input.is_action_just_pressed("ui_cancel"):
		hud.toggle_pause()

	if Input.is_action_just_pressed("Change"):
		change_weapon()
		
	if primary_weapon.visible and Engine.time_scale != 0:
		if Input.is_action_just_pressed("Attack"):
			primary_attack()
		if Input.is_action_just_pressed("Alt Attack"):
			primary_alt_attack()
		elif Input.is_action_just_released("Alt Attack"):
			anim_player.play("Idle", 0.3)
			is_blocking = false
	elif secondary_weapon.visible and Engine.time_scale != 0:
		if Input.is_action_just_pressed("Attack"):
			secondary_attack()
	
	handle_dash_input()
	
	if Input.is_action_just_pressed("Crouch"):
		toggle_crouch()

func handle_dash_input():
	var input_dir = Input.get_vector("Left", "Right", "Forwards", "Backwards")
	var is_moving_forward = input_dir.y < 0  # Note: Forward is negative in Godot's input system
	
	if Input.is_action_just_pressed("Dash") and dash_uses > 0 and not is_dashing and not is_charging:
		start_dash()
	
	if Input.is_action_pressed("Dash"):
		if is_moving_forward:
			is_sprinting = true
		else:
			is_sprinting = false
	else:
		is_sprinting = false
	
	if Input.is_action_just_released("Dash") and not is_dashing:
		if not is_moving_forward and dash_uses > 0:
			start_charge()

# Toggle crouch animation
func toggle_crouch():
	if is_crouching:
		is_crouching = false
		anim_player.play("Uncrouch")
	else:
		is_crouching = true
		anim_player.play("Crouch")

func start_charge():
	is_charging = true
	dash_uses -= 1
	dash_timer = DASH_DURATION
	# Get the forward direction of the camera
	charge_direction = -firstPersonCamera.global_transform.basis.z
	charge_direction = charge_direction.normalized()

func start_dash():
	is_dashing = true
	dash_timer = DASH_DURATION
	dash_uses -= 1

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

func move(delta: float):
	if is_charging:
		dash_timer -= delta
		if dash_timer > 0.0:
			velocity.x = charge_direction.x * CHARGE_SPEED
			velocity.z = charge_direction.z * CHARGE_SPEED
			velocity.y = charge_direction.y * CHARGE_SPEED
		else:
			is_charging = false
		return
		
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
	hud.update_dash(dash_uses)

func add_to_input_buffer(input: String):
	var current_time = Time.get_ticks_msec() / 1000.0
	
	# Remove old inputs
	while input_buffer.size() > 0 and current_time - input_times[0] > INPUT_BUFFER_TIME:
		input_buffer.pop_front()
		input_times.pop_front()
	
	# Add new input
	input_buffer.append(input)
	input_times.append(current_time)

func check_circular_motion() -> bool:
	if input_buffer.size() < 4:
		return false
	
	var circular_patterns = [
		["W", "A", "S", "D"],
		["A", "S", "D", "W"],
		["S", "D", "W", "A"],
		["D", "W", "A", "S"]
	]
	
	var last_four = input_buffer.slice(-4)
	for pattern in circular_patterns:
		if arrays_match(last_four, pattern):
			return true
	
	return false

func arrays_match(arr1: Array, arr2: Array) -> bool:
	if arr1.size() != arr2.size():
		return false
	
	for i in range(arr1.size()):
		if arr1[i] != arr2[i]:
			return false
	
	return true

func determine_move_type() -> String:
	var current_time = Time.get_ticks_msec() / 1000.0
	
	if check_circular_motion():
		print("Animation not created yet: Swirl")
		return "Swirl"
	
	# Check for thrust attack (Forward-Backward or Backward-Forward)
	if input_buffer.size() >= 2:
		var last_two = input_buffer.slice(-2)
		if (last_two[0] == "W" and last_two[1] == "S") or \
		   (last_two[0] == "S" and last_two[1] == "W"):
			print("Animation not created yet: Thrust")
			return "Thrust"
	
	# Check for directional attacks
	if input_buffer.size() > 0:
		match input_buffer[-1]:
			"W":
				return "Upper Slash"
			"S":
				print("Animation not created yet: Bottom Slash")
				return "Bottom Slash"
			"A":
				return "Left Slash"
			"D":
				return "Right Slash"
			
	
	# Default to regular attack (thrust)
	return "Thrust"

func primary_attack():
	primary_weapon_hitbox.monitoring = true
	var move_type = determine_move_type()
	
	anim_player.play(move_type)

func primary_alt_attack():
	is_blocking = true
	anim_player.play("Block")

func secondary_attack():
	if !is_shooting:
		anim_player.play("Shoot")
		var projectile = projectile_scene.instantiate()
		projectile.position = secondary_weapon_gunpoint.global_position
		projectile.transform.basis = secondary_weapon_gunpoint.global_transform.basis
		get_parent().add_child(projectile)

func secondary_alt_attack():
	pass

func take_damage(damage):
	if is_blocking:
		pass
	else:
		print(self.name + " took " + str(damage) + " damage")
		print("HP: " + str(hp) + " - " + str(damage) + " = " + str(hp - damage))
		hp = hp - damage
	hud.update_health(hp)

func change_weapon():
	if primary_weapon.visible:
		primary_weapon.visible = false
		secondary_weapon.visible = true
	elif secondary_weapon.visible:
		secondary_weapon.visible = false
		primary_weapon.visible = true

# Handle jump input
func handle_jump():
	if Input.is_action_just_pressed("Jump"):
		if is_on_floor():
			is_holding_jump = true
			jump_hold_timer = 0.0
	
	if Input.is_action_pressed("Jump"):
		if is_holding_jump and is_on_floor():
			jump_hold_timer += get_physics_process_delta_time()
		elif not is_on_floor():
			is_gliding = true
			if velocity.y < -GLIDE_FALL_SPEED:
				velocity.y = -GLIDE_FALL_SPEED
	
	if Input.is_action_just_released("Jump"):
		if is_holding_jump and is_on_floor():
			if jump_hold_timer >= HIGHJUMP_TIME:
				velocity.y = HIGHJUMP_VELOCITY
			else:
				velocity.y = JUMP_VELOCITY
			is_holding_jump = false
			ImpulseCamera(Vector3.UP, CameraShake_JumpingStrength)
		elif can_double_jump:
			velocity.y = DOUBLE_JUMP_VELOCITY
			can_double_jump = false
			ImpulseCamera(Vector3.UP, CameraShake_JumpingStrength)
		is_gliding = false

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

func _on_primary_weapon_hitbox_entered(area):
	if area.is_in_group("enemy"):
		area.take_damage(MELEE_DAMAGE)

func _on_animation_player_animation_finished(anim_name):
	if anim_name in ["Right Slash", "Left Slash", "Upper Slash"]:
		primary_weapon_hitbox.monitoring = false
		anim_player.play("Idle", 0.5)
	if anim_name == "Shoot":
		is_shooting = false
		anim_player.play("Idle", 0.5)

func update_item_detection():
	var collider = item_detector_raycast.get_collider()
		
	if collider is WorldItem and collider != highlighted_item:
		if highlighted_item:
			highlighted_item.unhighlight()
			
			highlighted_item = collider
			highlighted_item.highlight()
	elif highlighted_item:
		highlighted_item.unhighlight()
		highlighted_item = null

func interact_with_item():
	var collision_object = item_detector_raycast.get_collider()
	print(collision_object)
	if collision_object is WorldItem:
		var item_data = collision_object.interact_reaction()
		
		# Add to inventory
		if hud.add_item_to_inventory(item_data):
			# Remove from world if successfully added to inventory
			collision_object.queue_free()
			highlighted_item = null

func _on_inventory_item_dropped(item, position):
	var world_item = world_item_scene.instantiate()
	world_item.setup_from_item(item)

	# Place slightly in front of player
	var spawn_pos = global_position + -firstPersonCamera.global_transform.basis.z * 1.5
	spawn_pos.y = global_position.y - 0.5  # Slightly below eye level

	world_item.global_position = spawn_pos
	get_tree().current_scene.add_child(world_item)
