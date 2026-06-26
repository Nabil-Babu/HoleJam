extends CharacterBody3D
# Movement speeds
@export var WALK_SPEED: float = 5.0
@export var JUMP_VELOCITY: float = 4.5
@export var SPRINT_MULT: float = 1.5

# Look sensitivity
const MOUSE_SENSITIVITY: float = 0.003

# Get the gravity from the project settings to be sync'd with RigidBody nodes.
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D

func _enter_tree() -> void: 
	set_multiplayer_authority(name.to_int())

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if is_multiplayer_authority():
		$Head/Camera3D.current = true; 

func _input(event) -> void:
	
	if event is InputEventMouseMotion:
		
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		
		head.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("play_char_jump_action") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	var input_dir: Vector2 = Input.get_vector("play_char_move_left_action", "play_char_move_right_action", "play_char_move_forward_action", "play_char_move_backward_action")
	var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * WALK_SPEED
		velocity.z = direction.z * WALK_SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, WALK_SPEED)
		velocity.z = move_toward(velocity.z, 0, WALK_SPEED)
	
	# Multiply velocity by sprint mult factor when sprinting
	if Input.is_action_pressed("play_char_run_action"):
		velocity.x *= SPRINT_MULT
		velocity.z *= SPRINT_MULT
		
	# Execute built-in Godot physics simulation and collision handling
	move_and_slide()
	
	# Grabbing logic
	if Input.is_action_just_pressed("play_char_grab_action"):
		print("Im trying grab it")
