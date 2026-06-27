extends RigidBody3D

@export var attract_speed: float = 20.0
var target_transform: Marker3D = null
var is_following_target := false

func _ready() -> void:
	if not multiplayer.is_server():
		# Freeze the rigidbody on clients so local physics don't fight the server updates
		freeze = true 


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if not target_transform:
		return
	# Target position and orientation
	var target_pos: Vector3 = target_transform.global_position
	# Calculate physics velocity to move toward target
	var pos_delta: Vector3 = target_pos - global_position
	state.linear_velocity = pos_delta * attract_speed


func pickup(target: Marker3D) -> bool:
	if is_following_target:
		return false
	is_following_target = true
	target_transform = target
	print("I AM BEING GRABBED")
	print("My target state is " + str(target_transform))
	return true


func throw(direction: Vector3):
	is_following_target = false
	target_transform = null
	linear_velocity += direction * 10.0
