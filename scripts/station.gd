extends Area3D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	if body is RigidBody3D:
		body.set_collision_mask_value(4, false)
		if body.has_signal("box_despawn"):
			if !body.box_despawn.is_connected(_complete_station_task):
				body.box_despawn.connect(_complete_station_task)


func _on_body_exited(body: Node3D) -> void:
	if body is RigidBody3D:
		body.set_collision_mask_value(4, true)


func _complete_station_task():
	print("Station Complete!")
