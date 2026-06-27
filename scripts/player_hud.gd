extends Control

@onready var reticle: AnimatedSprite2D = $Reticle


func reticle_to_grab():
	reticle.play()


func reticle_to_idle():
	reticle.play_backwards()
