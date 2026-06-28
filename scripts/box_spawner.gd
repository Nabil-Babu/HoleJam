extends Node3D

@export var spawnTime : float = 1.0

@onready var label: Label3D = $Visuals/Label3D/LabelBoxDelivery
@onready var label2: Label3D = $Visuals/Label3D2/LabelBoxDelivery2

var main_server
var timer: float = 0.0
var label_text: String = " BPS (Boxes Per Second)"

func _ready() -> void:
	main_server = get_parent().get_parent() # sloppy ref grabbing


func _process(delta: float) -> void:
	timer += delta
	label.text = str(spawnTime) + label_text
	label2.text = str(spawnTime) + label_text
	if timer >= spawnTime:
		spawn_a_box.rpc()
		timer = 0.0


@rpc("any_peer", "call_local", "reliable")
func spawn_a_box():
	main_server.spawn_box()
