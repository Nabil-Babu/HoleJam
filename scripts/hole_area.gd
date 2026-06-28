extends Area3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
func _on_body_entered(body: Node3D) -> void:
	if body is RigidBody3D:
		if body.has_signal("box_despawn"):
			body.set_collision_mask_value(4, false)
			if !body.box_despawn.is_connected(_update_score.bind(body.boxScore)):
				body.box_despawn.connect(_update_score.bind(body.boxScore))
	if body is CharacterBody3D:
		body.set_collision_mask_value(4, false)


func _on_body_exited(body: Node3D) -> void:
	if body is RigidBody3D:
		body.set_collision_mask_value(4, true)
	if body is CharacterBody3D:
		body.set_collision_mask_value(4, true)
		body.call_deferred("set_global_position", Vector3(0,0,0))


func _update_score(points: int):
	get_parent().get_parent().update_game_score(points)
