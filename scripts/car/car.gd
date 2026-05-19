extends RigidBody3D
## The variables are tuned to a mass around 1000.0 kg
class_name Car

@export_category("Spring")
## Controls the overall stiffness of the suspension. Higher values = stiffer suspension, less body roll.
@export_range(0.5, 2.0, 0.1) var SPRING_STIFFNESS: float = 1.0
## Base spring force applied to keep the car at rest height. Calculated from SPRING_STIFFNESS.
var SPRING_STRENGTH := 20000.0 * SPRING_STIFFNESS
## Controls how quickly suspension oscillations are dampened. Higher values = less bouncing.
@export_range(0.5, 2.0, 0.1) var SPRING_DAMPENING: float = 1.0
## Damping force applied to reduce suspension bounce. Calculated from SPRING_DAMPENING.
var SPRING_DAMP := 600 * SPRING_DAMPENING
## Default suspension extension length when car is at rest (in meters).
@export var REST_DISTANCE := 0.5

@export_category("Wheels")
## Radius of the wheels in meters. Affects wheel spin calculation and ground clearance.
@export var WHEEL_RADIUS := 0.55

@export_category("Engine")
## Engine power in horsepower. Higher values = more acceleration force.
@export var HORSEPOWER: = 200.0
## Actual force multiplier applied for acceleration. Calculated from HORSEPOWER.
var ENGINE_POWER: float = 15 * HORSEPOWER
## Multiplier for ENGINE_POWER when going in reverse. Higher values = stronger braking.
@export_range(0.5, 2.0, 0.1) var BRAKE_FORCE: float = 1.5
## Force multiplier when handbrake is engaged. Higher values = stronger handbrake effect
@export_range(1.0, 4.0, 0.1) var HANDBRAKE: float = 3.0
var HANDBRAKE_FORCE: float = HANDBRAKE * 5.0
@onready var engine_audio: AudioStreamPlayer3D = $Sound/Engine

@export_category("Steering")
## Maximum steering angle in degrees. Higher values = sharper turning radius
@export var MAX_STEER_ANGLE: float = 30.0

@export_category("Transmission")
@export var is_automatic: bool = true
## Gear ratios. The first index is 1st gear, the second is 2nd gear, etc.
@export var gear_ratios: Array[float] = [2.66, 1.78, 1.30, 1.00, 0.74, 0.50]
@export var reverse_ratio: float = 1.90
## Length of the gears. The higher this, the shorter the gears.
@export var final_drive: float = 7.0
@export var max_rpm: float = 7000.0
@export var idle_rpm: float = 400.0

var current_gear: int = 1 # 1 for 1st gear, 0 for neutral, -1 for reverse
var engine_rpm: float = idle_rpm

# Input variables
## Current acceleration input (-1 to 1). Negative = reverse, positive = forward.
var accel_input: float
## Current steering input (-1 to 1). Negative = left, positive = right.
var steer_input: float
## Whether handbrake is currently engaged.
var handbrake: bool = false

func _process(delta: float) -> void:
	accel_input = Input.get_axis("reverse", "accelerate")
	steer_input = Input.get_axis("steer_left", "steer_right")
	if Input.is_action_just_pressed("handbrake"):
		handbrake = !handbrake
		Helper.play_single_sound(
			"res://assets/car/audio/handbrake_pull.wav" if handbrake
			else "res://assets/car/audio/handbrake_release.wav",
			self)
	
	_handle_transmission(delta)
	_engine_sound(delta)
	print(current_gear, "th gear")

func _handle_transmission(_delta: float):
	# Since car.transform.basis.z is the acceleration direction, it is the forward direction.
	var forward_speed = global_transform.basis.z.dot(linear_velocity)
	
	# Calculate RPM based on wheel speed
	var wheel_rpm = (abs(forward_speed) / WHEEL_RADIUS) * (60.0 / TAU)
	var current_ratio = reverse_ratio if current_gear == -1 else (0 if current_gear == 0 else gear_ratios[current_gear - 1])
	engine_rpm = wheel_rpm * current_ratio * final_drive
	if engine_rpm < idle_rpm:
		engine_rpm = idle_rpm

	if is_automatic:
		# Simple automatic shifting logic
		if current_gear > 0:
			if engine_rpm > max_rpm * 0.95 and current_gear < gear_ratios.size():
				current_gear += 1
			elif engine_rpm < max_rpm * 0.5 and current_gear > 1:
				current_gear -= 1
		
		# Drive vs Reverse logic based on velocity and input
		if forward_speed < 1.0 and accel_input < -0.1 and current_gear > 0:
			current_gear = -1
		elif forward_speed > -1.0 and accel_input > 0.1 and current_gear < 0:
			current_gear = 1
	else:
		if Input.is_action_just_pressed("shift_up") and current_gear < gear_ratios.size():
			if current_gear == -1: current_gear = 1
			else: current_gear += 1
		elif Input.is_action_just_pressed("shift_down") and current_gear > -1:
			if current_gear == 1: current_gear = -1
			else: current_gear -= 1

func _engine_sound(delta: float):
	var pitch = remap(engine_rpm, idle_rpm, max_rpm, 1.0, 3.0)
	# Add slight pitch increase on throttle
	if accel_input != 0:
		pitch += 0.2
	if handbrake && accel_input != 0:
		pitch += 0.5
	engine_audio.pitch_scale = lerp(engine_audio.pitch_scale, pitch, 10.0 * delta)

func _on_body_entered(_body: Node) -> void:
	# Play different crash sounds based on impact velocity
	if abs(self.linear_velocity.length()) > 10:
		#INFO This can be replaced with Helper.play_sound(), providing an array for random picking.		
		Helper.play_single_sound("res://assets/car/audio/crash_hard.wav", self)
	elif abs(self.linear_velocity.length()) > 5:
		Helper.play_single_sound("res://assets/car/audio/crash_mid.wav", self)
	elif abs(self.linear_velocity.length()) > 0.4:
		Helper.play_single_sound("res://assets/car/audio/crash_light.wav", self)
