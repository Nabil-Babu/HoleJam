extends RigidBody3D

@export var attract_speed: float = 20.0
@export var lowest_point: float = -10.0
@export var held_by_peer_id: int = 0


var target_transform: Marker3D = null
var is_following_target := false

func _ready() -> void:
	if not multiplayer.is_server():
		# Freeze the rigidbody on clients so local physics don't fight the server updates
		freeze = true 


func _process(_delta: float) -> void:
	if global_position.y < lowest_point:
		despawn.rpc()


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if not target_transform:
		return
	# Target position and orientation
	var target_pos: Vector3 = target_transform.global_position
	# Calculate physics velocity to move toward target
	var pos_delta: Vector3 = target_pos - global_position
	state.linear_velocity = pos_delta * attract_speed


func request_pickup(target: Marker3D):
	pickup.rpc(target.get_path())


func request_throw(direction: Vector3):
	throw.rpc(direction)


######## RPC Functions ########
@rpc("any_peer", "call_local", "reliable")
func pickup(path: NodePath):
	target_transform = get_node(path) as Marker3D
	apply_force(Vector3.UP) # need to call apply_force otherwise _integrate_forces doesnt get called


@rpc("any_peer", "call_local", "reliable")
func throw(direction: Vector3):
	linear_velocity += direction
	target_transform = null

@rpc("any_peer", "call_local", "reliable")
func despawn():
	print("Despawn me Satan!")
	queue_free()
