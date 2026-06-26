extends CharacterBody2D

const SPEED = 300.0


func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())
	position = get_viewport().size / 2.0

func _physics_process(_delta: float) -> void:
	if not is_multiplayer_authority():
		return
	
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if direction:
		velocity = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.y = move_toward(velocity.y, 0, SPEED)
	
	move_and_slide()
	print("Player named " + str(name) + " is at location: " + str(position))
	print("Player named " + str(name) + " has velocity: " + str(velocity))
