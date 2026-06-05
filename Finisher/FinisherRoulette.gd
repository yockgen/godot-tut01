extends Node2D
# Finisher Roulette - Visual indicator that cycles through finisher icons
# The roulette spins continuously; when the player triggers a finisher,
# the current frame determines which finisher is used.

@onready var animated_sprite = $AnimatedSprite2D

func _ready():
	# Ensure the roulette is always spinning
	animated_sprite.play("default")
	animated_sprite.speed_scale = 8.0  # Fast enough to look random

func get_selected_finisher() -> int:
	"""Return the current frame index (0-3)"""
	return animated_sprite.frame
