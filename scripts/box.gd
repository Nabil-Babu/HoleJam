extends Node3D
@onready var rb3D: RigidBody3D = $RigidBody3D

func _ready() -> void:
	if not multiplayer.is_server():
		# Freeze the rigidbody on clients so local physics don't fight the server updates
		rb3D.freeze = true 
