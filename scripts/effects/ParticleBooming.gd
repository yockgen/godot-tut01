extends Particles2D

func _ready():
	# Use a short lifetime for the particle effect and then free it
	yield(get_tree().create_timer(3.0), "timeout")
	queue_free()
