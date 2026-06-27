extends RigidBody3D

@export var attract_speed: float = 20.0
@export var held_by_peer_id: int = 0


var target_transform: Marker3D = null
var throw_dir: Vector3
var is_following_target := false

func _ready() -> void:
	if not multiplayer.is_server():
		# Freeze the rigidbody on clients so local physics don't fight the server updates
		freeze = true 


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if not target_transform and not is_following_target:
		return
	# Target position and orientation
	var target_pos: Vector3 = target_transform.global_position
	# Calculate physics velocity to move toward target
	var pos_delta: Vector3 = target_pos - global_position
	state.linear_velocity = pos_delta * attract_speed


func request_pickup(target: Marker3D):
	if multiplayer.is_server():
		target_transform = target
		rpc_id(1, "pickup")


@rpc("any_peer", "call_local", "reliable")
func pickup():
	is_following_target = true
	print("I AM BEING GRABBED and my target state is " + str(target_transform))


func request_throw(direction: Vector3):
	if multiplayer.is_server():
		target_transform = null
		throw_dir = direction
		rpc_id(1, "throw")


@rpc("any_peer", "call_local", "reliable")
func throw():
	is_following_target = false
	linear_velocity += throw_dir * 10.0
