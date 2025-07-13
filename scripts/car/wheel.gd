extends RayCast3D
class_name Wheel
@onready var car: Car = get_parent().get_parent()
@onready var mesh: MeshInstance3D = %Mesh
var mesh_rotation_x: float = 0.0

@export var use_as_traction: bool = false
@export var use_as_steering: bool = false

@export var TIRE_GRIP: float = 20.0
@export var ROLLING_FRICTION: float = 20.0

@onready var rot = rotation
@onready var pos = position
@onready var initial_position: Vector3 = position # Store initial local position for mesh offset

var last_rot_vel: = 0.0
var prev_spring_length: float = 0.0
var wheel_point: Vector3

func _physics_process(delta: float) -> void:
	#rotate
	if use_as_steering: 
		_steer(delta)
	if is_colliding():
		## Collision point in GLOBAL coordinates
		var collision_point = get_collision_point()
		wheel_point = collision_point + Vector3(0, car.WHEEL_RADIUS, 0)
		_apply_z_force(collision_point)
		_apply_lateral_force(collision_point)
		if car.accel_input == 0:
			_apply_rolling_friction(collision_point)
		_suspension(delta, collision_point)
		_wheel_spin(delta, collision_point)
		if car.handbrake:
			_apply_rolling_friction(collision_point, car.handbrake)
			return
		
		if use_as_traction:
			_acceleration(collision_point)
		

	else:
		_wheel_spin(delta)

func _steer(_delta):
	var rad_angle = deg_to_rad(car.MAX_STEER_ANGLE)
	var steering_rotation = car.steer_input * rad_angle 
	var angle = clamp(steering_rotation,-rad_angle, rad_angle)
	if steering_rotation != 0:
		rotation.y = lerp(rotation.y, rot.y - angle, 0.1)
	else:
		rotation.y = lerp(rotation.y, rot.y, 0.1)
		
func _suspension(delta, point):
	var suspension_direction := global_basis.y
	var distance = point.distance_to(global_position)
	var spring_length = clamp(distance - car.WHEEL_RADIUS, 0.0, car.REST_DISTANCE)
	var spring_force = car.SPRING_STRENGTH * (car.REST_DISTANCE - spring_length)
	var spring_velocity = (prev_spring_length - spring_length) / delta
	var damper_force = car.SPRING_DAMP * spring_velocity
	var suspension_force = basis.y * (spring_force + damper_force)
	prev_spring_length = spring_length
	car.apply_force(suspension_direction * suspension_force, wheel_point - car.global_position)
	mesh.position.y = -spring_length

func _acceleration(point):
	var mult = car.ENGINE_POWER
	if (car.accel_input * -global_transform.basis.z.dot(car.linear_velocity)) > 0: #reverse
		mult = car.BRAKE_FORCE
	var f = car.transform.basis.z * mult * car.accel_input 
	car.apply_force(f, point-car.global_position)

func _get_point_velocity(point: Vector3) -> Vector3:
	return car.linear_velocity + car.angular_velocity.cross(point - car.global_position)

func _apply_z_force(point: Vector3):
	var dir = car.transform.basis.x
	var tire_world_vel = _get_point_velocity(global_position)
	var z_force = dir.dot(tire_world_vel) * car.mass
	car.apply_force(-dir * z_force, point-car.global_position)

func _apply_lateral_force(point: Vector3): # sideways, to steer
	var wheel_world_velocity = car.linear_velocity + car.angular_velocity.cross(point - car.global_position)
	var wheel_sideways_dir = global_basis.x
	var lateral_velocity_magnitude = wheel_world_velocity.dot(wheel_sideways_dir)
	var lateral_force = -wheel_sideways_dir * lateral_velocity_magnitude * TIRE_GRIP * 3.0
	car.apply_force(lateral_force, point - car.global_position)

func _apply_rolling_friction(point: Vector3, handbrake: bool = false):
	var wheel_forward_dir = global_basis.z
	var total_longitudinal_force := 0.0
	var wheel_world_velocity = car.linear_velocity + car.angular_velocity.cross(point - car.global_position)
	var longitudinal_velocity_magnitude = wheel_world_velocity.dot(wheel_forward_dir)
	total_longitudinal_force = -longitudinal_velocity_magnitude * ROLLING_FRICTION 
	if handbrake:
		total_longitudinal_force *= car.HANDBRAKE_FORCE
	car.apply_force(wheel_forward_dir * total_longitudinal_force, point - car.global_position)

## Returns angular wheel speed (good for engine sound)
func _wheel_spin(delta: float, collision_point: Vector3 = Vector3.ZERO) -> float:
	var wheel_world_velocity = _get_point_velocity(collision_point) 
	if collision_point == Vector3.ZERO:
		if use_as_traction:
			wheel_world_velocity = Vector3(0, 0, car.accel_input) * car.ENGINE_POWER
		else:
			last_rot_vel = last_rot_vel / 1.01 # slowly stop spinning
			mesh_rotation_x += last_rot_vel * delta
			mesh.rotation.x = mesh_rotation_x
			return last_rot_vel * delta
	var wheel_forward_dir = global_basis.z 
	var longitudinal_velocity = wheel_world_velocity.dot(wheel_forward_dir)
	var angular_velocity_rad_per_sec = -longitudinal_velocity / car.WHEEL_RADIUS 
	mesh_rotation_x += angular_velocity_rad_per_sec * delta
	last_rot_vel = angular_velocity_rad_per_sec
	mesh.rotation.x = mesh_rotation_x
	return angular_velocity_rad_per_sec * delta
