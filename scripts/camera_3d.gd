# camera_orbit.gd
extends Node3D

@export var target_node: Node3D # The node the camera will orbit around (e.g., your car)
@export var spring_arm_length: float = 10.0 # Length of the SpringArm3D (camera's desired distance from target)
@export var rotation_speed: float = 0.2 # How fast the camera rotates with mouse input
@export var min_tilt_angle: float = -90.0 # Minimum vertical angle (looking up/down) in degrees
@export var max_tilt_angle: float = 90.0 # Maximum vertical angle (looking up/down) in degrees

@export var auto_rotate_delay: float = 2.0 # Time in seconds after last manual input before auto-rotation kicks in
@export var auto_rotate_speed: float = 2.0 # Speed of auto-rotation (higher value means faster snap to car's direction)
@export var movement_threshold: float = 0.5 # Minimum linear velocity for the car to be considered "moving"

var current_yaw: float = 0.0 # Horizontal rotation (around Y-axis)
var current_pitch: float = 0.0 # Vertical rotation (around X-axis)
var last_manual_input_time: float = 0.0 # Stores the last time mouse input was received for camera rotation

@onready var spring_arm: SpringArm3D = $SpringArm3D # Assumes SpringArm3D is a direct child of this Node3D
@onready var camera_3d: Camera3D = null # Will be assigned from the SpringArm3D's children

func _ready():
	if not spring_arm:
		print("Error: No SpringArm3D found as a child of this Node3D (CameraPivot).")
		set_process(false) # Disable script if no spring arm
		return
	for child in spring_arm.get_children():
		if child is Camera3D:
			camera_3d = child
			break

	if not camera_3d:
		print("Error: No Camera3D found as a child of the SpringArm3D.")
		set_process(false) # Disable script if no camera
		return
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	spring_arm.spring_length = spring_arm_length
	camera_3d.position = Vector3.ZERO

	if target_node:
		look_at(target_node.global_position, Vector3.UP)
	else:
		# If no target node, just look forward from the pivot's position
		look_at(global_position, Vector3.UP)
	current_yaw = rotation.y
	current_pitch = rotation.x
	last_manual_input_time = Time.get_ticks_msec() / 1000.0


func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		current_yaw -= deg_to_rad(event.relative.x * rotation_speed)
		current_pitch -= deg_to_rad(event.relative.y * rotation_speed)
		current_pitch = clamp(current_pitch, deg_to_rad(min_tilt_angle), deg_to_rad(max_tilt_angle))
		rotation = Vector3(current_pitch, current_yaw, 0)
		last_manual_input_time = Time.get_ticks_msec() / 1000.0

	# Press ESC to release mouse capture, allowing mouse interaction outside the game window
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	# Click to re-capture mouse, useful after releasing it with ESC
	if event.is_action_pressed("ui_accept") and Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
	if target_node:
		global_position = target_node.global_position
		# Auto-rotate camera to face car's forward direction if moving and player is inactive
		var time_since_last_input = Time.get_ticks_msec() / 1000.0 - last_manual_input_time
		var is_car_moving = false

		if target_node is RigidBody3D:
			is_car_moving = target_node.linear_velocity.length() > movement_threshold

		if is_car_moving and time_since_last_input > auto_rotate_delay:
			var car_forward_global = -target_node.global_transform.basis.z.normalized()
			var target_yaw = atan2(car_forward_global.x, car_forward_global.z)
			current_yaw = lerp_angle(current_yaw, target_yaw, auto_rotate_speed * delta)
			rotation = Vector3(current_pitch, current_yaw, 0)
