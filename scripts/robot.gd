extends CharacterBody3D

const ROTATION_SPEED = 10.0 # Adjust to change how fast the character turns
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@export var SPEED: float = 5.0
@export var direction: Vector3 = Vector3(0, 0, 1) # Direction to start walking
@onready var robot_mesh: Node3D = $RobotMesh
@onready var col_shape: CollisionShape3D = $CollisionShape3D
@onready var col_shape_2: CollisionShape3D = $CollisionShape3D2


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
		
	velocity.x = direction.x * SPEED
	velocity.z = direction.z * SPEED
	move_and_slide()
	
	# Calculate target rotation angle
	var target_angle = atan2(direction.x, direction.z)
	# Smoothly rotate the visual node
	robot_mesh.rotation.y = lerp_angle(robot_mesh.rotation.y, target_angle, ROTATION_SPEED * delta)
	col_shape.rotation.y = lerp_angle(col_shape.rotation.y, target_angle, ROTATION_SPEED * delta)
	col_shape_2.rotation.y = lerp_angle(col_shape_2.rotation.y, target_angle, ROTATION_SPEED * delta)
		
	# Turn around if hitting a wall
	if is_on_wall():
		direction *= -1
