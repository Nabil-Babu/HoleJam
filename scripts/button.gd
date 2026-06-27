extends StaticBody3D

@onready var animator: AnimationPlayer = $AnimationPlayer
var main_server

func _ready() -> void:
	main_server = get_parent().get_parent() # sloppy ref grabbing

func interact():
	rpc("trigger_button_press")
	#if multiplayer.is_server():
		#rpc("trigger_button_press")
	#else:
		#rpc_id(1, "trigger_button_press")

@rpc("any_peer", "call_local", "reliable")
func trigger_button_press():
	animator.play("press_button")
	main_server.spawn_box()
