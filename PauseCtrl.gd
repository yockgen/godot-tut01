extends Node

export(bool) var can_toggle_pause: bool = true

func _process(delta):
	if Input.is_action_just_pressed("pause"):
		if !get_tree().paused:
			pause()
		else:
			resume()

func pause():
	if can_toggle_pause:
		get_tree().set_deferred("paused", true)

func resume():
	if can_toggle_pause:
		get_tree().set_deferred("paused", false)
