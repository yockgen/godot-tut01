extends Attack
# Basic melee attack
# Swing once and deal damage to nearby enemies

class_name BasicAttack

# ============ CONFIGURATION ============

func _ready():
	attack_name = "Basic Attack"
	damage = 10
	cooldown = 0.3
	animation_name = "swing"

# ============ ATTACK EXECUTION ============

func _perform_attack(target_position: Vector2):
	"""Execute basic attack animation and hitbox"""
	if player_ref == null:
		return
	
	# Play attack animation
	if player_ref.has_node("AnimatedSprite"):
		var sprite = player_ref.get_node("AnimatedSprite")
		sprite.animation = animation_name
		sprite.play()
	
	# Emit damage signal (actual hitbox detection happens in player collision logic)
	# This will be expanded in Phase 2 with actual hitbox system
	
	# Schedule finish after animation
	var animation_length = _get_animation_length()
	yield(get_tree().create_timer(animation_length), "timeout")
	finish_execution()

func _get_animation_length() -> float:
	"""Get duration of attack animation"""
	if player_ref == null or not player_ref.has_node("AnimatedSprite"):
		return 0.3
	
	var sprite = player_ref.get_node("AnimatedSprite")
	var frames = sprite.frames
	
	if frames == null or not frames.has_animation(animation_name):
		return 0.3
	
	var frame_count = frames.get_frame_count(animation_name)
	var fps = frames.get_animation_speed(animation_name)
	
	if fps == 0:
		fps = 10  # Default fallback
	
	return float(frame_count) / fps
