extends CharacterBody3D
# Movement speeds
@export var WALK_SPEED: float = 5.0
@export var JUMP_VELOCITY: float = 4.5
@export var SPRINT_MULT: float = 1.5
@export var THROW_SPEED: float = 10.0

# Look sensitivity
const MOUSE_SENSITIVITY: float = 0.003

# Get the gravity from the project settings to be sync'd with RigidBody nodes.
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var held_object = null

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var player_mesh: Node3D = $PlayerMesh
@onready var grab_anchor: Node3D = $Head/GrabAnchor
@onready var interaction_raycast: RayCast3D = $Head/InteractionRaycast
@onready var target_indicator: MeshInstance3D = $TargetIndicator

func _enter_tree() -> void: 
	set_multiplayer_authority(name.to_int())

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if is_multiplayer_authority():
		camera.current = true; 
		player_mesh.visible = false


func _input(event) -> void:
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		head.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))
		
	if interaction_raycast.is_colliding() and not held_object:
		target_indicator.show()
		target_indicator.global_position = interaction_raycast.get_collision_point() 
		#target_indicator.global_position.y + 2.0
	else:
		target_indicator.hide()
	if event.is_action_pressed("grab") and is_multiplayer_authority():
		#print("doing a grab move from player: " + str(multiplayer.get_unique_id()))
		if held_object:
			held_object.request_throw(-camera.global_transform.basis.z * THROW_SPEED)
			held_object = null
			return
		var collider: Object = interaction_raycast.get_collider()
		if collider:
			if collider.has_method("interact"):
				collider.interact()
			if collider.has_method("request_pickup"):
				collider.request_pickup(grab_anchor)
				held_object = collider
		

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	#print(input_dir)

	if direction:
		velocity.x = direction.x * WALK_SPEED
		velocity.z = direction.z * WALK_SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, WALK_SPEED)
		velocity.z = move_toward(velocity.z, 0, WALK_SPEED)
	
	# Multiply velocity by sprint mult factor when sprinting
	if Input.is_action_pressed("sprint"):
		velocity.x *= SPRINT_MULT
		velocity.z *= SPRINT_MULT
		
	# Execute built-in Godot physics simulation and collision handling
	move_and_slide()
	
	# Grabbing logic
	if Input.is_action_just_pressed("grab"):
		pass
