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

# Input variables
## Current acceleration input (-1 to 1). Negative = reverse, positive = forward.
var accel_input: float
## Current steering input (-1 to 1). Negative = left, positive = right.
var steer_input: float
## Whether handbrake is currently engaged.
var handbrake: bool = false

func _process(_delta: float) -> void:
	accel_input = Input.get_axis("reverse", "accelerate")
	steer_input = Input.get_axis("steer_left", "steer_right")
	if Input.is_action_just_pressed("handbrake"):
		handbrake = !handbrake
		Helper.play_single_sound(
			"res://assets/car/audio/handbrake_pull.wav" if handbrake
			else "res://assets/car/audio/handbrake_release.wav",
			self)
	_engine_sound()

func _engine_sound():
	# Calculate forward velocity for engine pitch
	var f_v = -global_transform.basis.z.dot(linear_velocity)
	# Adjust pitch based on speed and throttle input
	var pitch = remap(abs(f_v), 0, 20, 1, 2) * remap(abs(accel_input), 0, 1, 1, 2)
	# Increase pitch when handbrake is engaged and accelerating (tire spinning)
	if handbrake && accel_input != 0:
		pitch += 1
	engine_audio.pitch_scale = lerp(engine_audio.pitch_scale, pitch, 0.01)

func _on_body_entered(_body: Node) -> void:
	# Play different crash sounds based on impact velocity
	if abs(self.linear_velocity.length()) > 10:
		#INFO This can be replaced with Helper.play_sound(), providing an array for random picking.		
		Helper.play_single_sound("res://assets/car/audio/crash_hard.wav", self)
	elif abs(self.linear_velocity.length()) > 5:
		Helper.play_single_sound("res://assets/car/audio/crash_mid.wav", self)
	elif abs(self.linear_velocity.length()) > 0.4:
		Helper.play_single_sound("res://assets/car/audio/crash_light.wav", self)
