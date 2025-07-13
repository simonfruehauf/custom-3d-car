extends RigidBody3D
class_name  Car
@export var SPRING_STRENGTH := 2000.0
@export var SPRING_DAMP := 100
@export var REST_DISTANCE := 0.5
@export var WHEEL_RADIUS := 0.55
@export var WHEEL_WIDTH := 0.2

@export var ENGINE_POWER: float = 200.0
@export var BRAKE_FORCE: float = 250.0
@export var HANDBRAKE_FORCE: float = 2.0

@onready var engine_audio: AudioStreamPlayer3D = $Sound/Engine
@export var MAX_STEER_ANGLE: float = 30.0

var accel_input: float
var steer_input: float
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
	var f_v = -global_transform.basis.z.dot(linear_velocity)
	var pitch = remap(abs(f_v), 0, 20, 1, 2) * remap(abs(accel_input), 0, 1, 1, 2)
	if handbrake && accel_input != 0:
		pitch += 1
	engine_audio.pitch_scale = lerp(engine_audio.pitch_scale, pitch, 0.01)
	pass

func _on_body_entered(_body: Node) -> void:
	print(self.linear_velocity)
	if abs(self.linear_velocity.length()) >  10:
		Helper.play_single_sound("res://assets/car/audio/crash_hard.wav", self)
	elif abs(self.linear_velocity.length()) >  5:
		Helper.play_single_sound("res://assets/car/audio/crash_mid.wav", self)
	elif abs(self.linear_velocity.length()) >  0.4:
		Helper.play_single_sound("res://assets/car/audio/crash_light.wav", self)
