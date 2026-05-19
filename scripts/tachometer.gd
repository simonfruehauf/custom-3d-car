extends Control

@export var car : Car

@export var max_speed_kmh := 160.0
@export var min_angle_deg := -150.0
@export var max_angle_deg := 0.0
@export var smooth_speed := 10.0

@onready var needle : Control = %Needle

var use_mph := true

func _ready():
	if not car:
		push_error("Needle: Car not set")

func _process(_delta) -> void:
	if not car:
		return
	var speed = car.speed_mph if use_mph else car.speed_kmh
	var target_angle = _speed_to_angle(speed)
	needle.rotation_degrees = target_angle

func _speed_to_angle(speed_val: float) -> float:
	var display_max = max_speed_kmh if not use_mph else max_speed_kmh * 0.621371
	var ratio = clamp(speed_val / display_max, 0.0, 1.0)
	return lerp(min_angle_deg, max_angle_deg, ratio)
