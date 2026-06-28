extends Area3D

@onready var output_location: Node3D = $"../OutputLocation"

var labelled_box_scene: PackedScene = preload("res://scenes/box_labelled.tscn")
var input_box_scale: Vector3
var labelled_box_count: int = 0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	if body is RigidBody3D:
		if body.has_signal("box_despawn"):
			if body.is_labelled:
				return
			body.set_collision_mask_value(4, false)
			input_box_scale = body.scale
			if !body.box_despawn.is_connected(_complete_station_task):
				body.box_despawn.connect(_complete_station_task)


func _on_body_exited(body: Node3D) -> void:
	if body is RigidBody3D:
		body.set_collision_mask_value(4, true)


func _complete_station_task():
	#print("Station Complete!")
	spawn_labelled_box(input_box_scale)


func spawn_labelled_box(input_scale: Vector3):
	if not multiplayer.is_server():
		return
	#print("LABEL INCOMING")
	labelled_box_count += 1
	var box: Node = labelled_box_scene.instantiate()
	box.set_multiplayer_authority(1) # set to server id = 1
	#box.box_despawn.connect(box_despawned)
	box.is_labelled = true
	box.scale = input_box_scale
	box.boxScore *= 2
	box.name = "BOX_LABELLED_" + str(labelled_box_count)
	output_location.call_deferred("add_child", box, true)
