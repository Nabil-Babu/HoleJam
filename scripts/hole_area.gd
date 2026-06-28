extends Area3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
func _on_body_entered(body: Node3D) -> void:
	if body is RigidBody3D:
		body.set_collision_mask_value(3, false)
		if body.has_signal("box_despawn"):
			body.box_despawn.connect(_update_score)


func _on_body_exited(body: Node3D) -> void:
	if body is RigidBody3D:
		body.set_collision_mask_value(3, true)


func _update_score():
	get_parent().get_parent().update_game_score(10)
