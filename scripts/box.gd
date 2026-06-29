extends RigidBody3D

signal box_despawn

@export var attract_speed: float = 20.0
@export var lowest_point: float = -10.0
@export var held_by_peer_id: int = 0

@export var XsizeRange: Vector2 = Vector2(1.0, 2.0)
@export var YsizeRange: Vector2 = Vector2(1.0, 2.0)
@export var ZsizeRange: Vector2 = Vector2(1.0, 2.0)


var boxScore: int = 10
var target_transform: Marker3D = null
var is_following_target := false
var is_labelled := false

func _ready() -> void:
	if not multiplayer.is_server():
		# Freeze the rigidbody on clients so local physics don't fight the server updates
		freeze = true 
	else: 
		if not is_labelled:
			scale.x = randf_range(XsizeRange.x, XsizeRange.y)
			scale.y = randf_range(YsizeRange.x, YsizeRange.y)
			scale.z = randf_range(ZsizeRange.x, ZsizeRange.y)
		elif $Labels:
			$Labels.scale.x = 1.0 / scale.x
			$Labels.scale.z = 1.0 / scale.z


func _process(_delta: float) -> void:
	if global_position.y < lowest_point:
		despawn.rpc()
		
func _physics_process(_delta: float) -> void:
	if target_transform:
		set_rotation(rotation.slerp(target_transform.global_rotation, attract_speed * _delta))


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
	box_despawn.emit()
	queue_free()
