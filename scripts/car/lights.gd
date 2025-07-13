extends Node3D

@onready var FL = %FL
@onready var FR = %FR
@onready var BL = %BL
@onready var BR = %BR
@onready var BrakeLR = %BrakeLightR
@onready var BrakeLL = %BrakeLightL
@onready var car: Car = get_parent()
const LIGHT_RANGE: float = 12.0
const BEAM_RANGE: float = 27.0
var lights: bool = true
var highbeams: bool = false

var brake_lights: bool = false:
	set(value):
		if value != brake_lights:
			_toggle_light(BrakeLL, value)
			_toggle_light(BrakeLR, value)
			brake_lights = value

func _ready() -> void:
	_toggle_light(BrakeLL, car.accel_input < 0)
	_toggle_light(BrakeLR, car.accel_input < 0)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("highbeams") && lights:
		highbeams = !highbeams
		_toggle_light(FL, lights, (LIGHT_RANGE if !highbeams else BEAM_RANGE))
		_toggle_light(FR, lights, (LIGHT_RANGE if !highbeams else BEAM_RANGE))
		Helper.play_single_sound("res://assets/car/audio/switch.wav", self, -5, 1.2 if highbeams else 1.1)

	if Input.is_action_just_pressed("lights"):
		lights = !lights
		_toggle_light(BL, lights)
		_toggle_light(BR, lights)
		_toggle_light(FL, lights, (LIGHT_RANGE if lights else 0.0))
		_toggle_light(FR, lights, (LIGHT_RANGE if lights else 0.0))
		Helper.play_single_sound("res://assets/car/audio/switch.wav", self, -5, 1.0 if lights else 0.5)
	if car.accel_input < 0:
		brake_lights = true
	else:
		brake_lights = false
		

func _toggle_light(l:Light3D, on:bool, l_range: float = 0.0):
	if on:
		l.show()
	l.light_energy = 2.0 if highbeams else 0.6
	if l is SpotLight3D:
		var tween = create_tween()
		tween.tween_property(l, "spot_range", l_range , 0.05).from_current()
		
		for c in l.get_children():
			if c is Light3D:
				if on:
					c.show()
				else:
					c.hide()
		await tween.finished
	if !on:
		l.hide()

	
