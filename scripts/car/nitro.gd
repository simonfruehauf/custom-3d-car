extends Node3D
@onready var car: Car = get_parent()
@export var NITRO_STRENGTH = 2000.0
## Total amount of nitro.
@export var NITRO_AMOUNT = 1.5
var debug_label: Label
var nitro_current = NITRO_AMOUNT
## Per second use of nitro.
@export var NITRO_USE = 0.5
## Per second refill of nitro.
@export var NITRO_REFILL = 0.25
## Delay before nitro starts to refill. Set to -1 for no refilling.
@export var NITRO_DELAY = 0.5
var waiting = false
var refilling = true

func _process(delta: float) -> void:
	if Input.is_action_pressed("nitro"):
		refilling = false
		if nitro_current > 0:
			nitro_current = clamp(nitro_current - (NITRO_USE * delta), 0, NITRO_AMOUNT)
			_nitro()
	if Input.is_action_just_released("nitro") && !waiting:
		waiting = true
		if NITRO_DELAY != -1:
			await get_tree().create_timer(NITRO_DELAY).timeout
			waiting = false
			refilling = true
	if refilling && nitro_current < NITRO_AMOUNT:
		nitro_current = clamp(nitro_current + (NITRO_REFILL * delta), 0, NITRO_AMOUNT)
	debug_label.text = str("Nitro: ", round(nitro_current*100) / 100)

func _nitro():
	var f = car.transform.basis.z * NITRO_STRENGTH
	car.apply_force(f)

func _ready():
	debug_label = Helper.new_debug_label()
