extends AIBehavior
# Attack behavior: Stationary enemy that attacks in place

class_name AttackBehavior

# ============ PROPERTIES ============
var attack_cooldown = 1.0
var attack_cooldown_timer = 0.0

# ============ LIFECYCLE ============

func _ready():
	behavior_state = State.IDLE
	attack_cooldown_timer = 0.0

# ============ BEHAVIOR LOGIC ============

func _update_behavior(delta: float):
	"""Update attack behavior"""
	match behavior_state:
		State.IDLE:
			_update_idle(delta)
		State.ATTACK:
			_update_attack(delta)
		_:
			pass

func _update_idle(delta: float):
	"""Wait for player to come in range"""
	if is_player_in_detection_range():
		change_state(State.ATTACK)

func _update_attack(delta: float):
	"""Attack state"""
	# Check if player is still in range
	if not is_player_in_detection_range():
		change_state(State.IDLE)
		return
	
	# Update cooldown
	attack_cooldown_timer -= delta
	
	# Attack if ready
	if attack_cooldown_timer <= 0:
		_perform_attack()
		attack_cooldown_timer = attack_cooldown

func _perform_attack():
	"""Override in subclasses or use entity's attack system"""
	# This is a placeholder - actual attacks would be implemented
	# via entity's attack system in Phase 4
	pass

# ============ MOVEMENT ============

func get_movement_direction() -> Vector2:
	"""Stationary - no movement"""
	return Vector2.ZERO

# ============ CONFIGURATION ============

func set_attack_cooldown(cooldown: float):
	"""Set time between attacks"""
	attack_cooldown = cooldown

func reset_attack_cooldown():
	"""Reset attack cooldown"""
	attack_cooldown_timer = 0.0
