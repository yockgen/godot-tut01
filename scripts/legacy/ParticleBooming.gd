extends Particles2D

# Called when the node enters the scene tree for the first time.
func _ready():
	# Use reasonable particle lifetime instead of 10 second wasteful timer
	await get_tree().create_timer(3.0).timeout
	queue_free()
