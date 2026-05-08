extends AIBehavior
# Patrol behavior: Wander in an area, chase if player detected

class_name PatrolBehavior

# ============ PROPERTIES ============
var patrol_direction = 1  # 1 or -1 for left/right
var patrol_bounds_left = -400
var patrol_bounds_right = 400
var wander_timer = 2.0  # Change direction every 2 seconds

# ============ LIFECYCLE ============

func _ready():
	behavior_state = State.PATROL
	state_timer = wander_timer

# ============ BEHAVIOR LOGIC ============

func _update_behavior(delta: float):
	"""Update patrol behavior"""
	match behavior_state:
		State.PATROL:
			_update_patrol(delta)
		State.CHASE:
			_update_chase(delta)
		_:
			pass

func _update_patrol(delta: float):
	"""Patrol movement logic"""
	# Check if player is detected
	if is_player_in_detection_range():
		change_state(State.CHASE)
		return
	
	# Random direction changes
	state_timer -= delta
	if state_timer <= 0:
		patrol_direction = -patrol_direction
		state_timer = wander_timer

func _update_chase(delta: float):
	"""Chase movement logic"""
	# Check if player is out of range
	if not is_player_in_detection_range():
		change_state(State.PATROL)
		return
	
	# If in attack range, could transition to attack
	if is_player_in_attack_range():
		# Could trigger attack here (implement in Phase 4 with attack system)
		pass

# ============ MOVEMENT ============

func get_movement_direction() -> Vector2:
	"""Return movement direction based on current state"""
	match behavior_state:
		State.PATROL:
			return Vector2(patrol_direction * patrol_speed, 0)
		State.CHASE:
			return get_direction_to_player() * chase_speed
		_:
			return Vector2.ZERO

# ============ CONFIGURATION ============

func set_patrol_bounds(left: float, right: float):
	"""Set left/right boundaries for patrol area"""
	patrol_bounds_left = left
	patrol_bounds_right = right

func set_detection_range(range_value: float):
	"""Set how far away player needs to be to trigger chase"""
	detection_range = range_value
