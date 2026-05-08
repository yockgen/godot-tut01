extends AIBehavior
# Chase behavior: Aggressive enemy that pursues player

class_name ChaseBehavior

# ============ CONFIGURATION ============
export var always_active = false  # If true, chase from start (no detection range needed)

# ============ LIFECYCLE ============

func _ready():
	if always_active:
		behavior_state = State.CHASE
	else:
		behavior_state = State.PATROL

# ============ BEHAVIOR LOGIC ============

func _update_behavior(delta: float):
	"""Update chase behavior"""
	match behavior_state:
		State.PATROL:
			_update_patrol(delta)
		State.CHASE:
			_update_chase(delta)
		State.ATTACK:
			_update_attack(delta)
		_:
			pass

func _update_patrol(delta: float):
	"""Idle until player detected"""
	if is_player_in_detection_range():
		change_state(State.CHASE)

func _update_chase(delta: float):
	"""Chase the player"""
	if always_active:
		# Always chase, never stop
		return
	
	# Stop chasing if player gets too far
	if not is_player_in_detection_range():
		change_state(State.PATROL)
		return
	
	# Attack if close enough
	if is_player_in_attack_range():
		change_state(State.ATTACK)

func _update_attack(delta: float):
	"""Attack state (placeholder for future attack system)"""
	if not is_player_in_attack_range():
		change_state(State.CHASE)

# ============ MOVEMENT ============

func get_movement_direction() -> Vector2:
	"""Return movement direction"""
	match behavior_state:
		State.CHASE, State.ATTACK:
			return get_direction_to_player() * chase_speed
		State.PATROL:
			return Vector2.ZERO  # Don't move while patrolling
		_:
			return Vector2.ZERO

# ============ CONFIGURATION ============

func set_always_active(active: bool):
	"""If true, enemy always chases without detection"""
	always_active = active
	if active and behavior_state == State.PATROL:
		change_state(State.CHASE)
