extends Node3D

@export var spawnTime : float = 2.0

@onready var label: Label3D = $Visuals/Label3D/LabelBoxDelivery
@onready var label2: Label3D = $Visuals/Label3D2/LabelBoxDelivery2

var main_server
@export var is_started := false
var timer: float = 0.0
var label_text: String = " BPS (Boxes Per Second)"

func _ready() -> void:
	main_server = get_parent().get_parent() # sloppy ref grabbing
	main_server.game_started.connect(start_spawning)


func _process(delta: float) -> void:
	if not multiplayer.is_server() or not is_started:
		return
	#print("test this spawner")
	timer += delta
	label.text = str(spawnTime) + label_text
	label2.text = str(spawnTime) + label_text
	if timer >= spawnTime:
		#print("now we spawning")
		spawn_a_box.rpc_id(1)
		timer = 0.0


func start_spawning():
	is_started = true


@rpc("any_peer", "call_local", "reliable")
func spawn_a_box():
	main_server.spawn_box()
