extends Node
# Base class for enemy AI behaviors
# Handles movement, decision-making, and state transitions

class_name AIBehavior

# ============ SIGNALS ============
signal behavior_changed(old_behavior, new_behavior)

# ============ PROPERTIES ============
var entity = null  # RefCounted to the entity using this behavior
var player_ref = null
var behavior_state = State.IDLE
var state_timer = 0.0

# ============ STATE ENUM ============
enum State {
	IDLE,
	PATROL,
	CHASE,
	ATTACK,
	RETREAT,
	DEAD
}

# ============ PARAMETERS ============
@export var detection_range = 300
@export var attack_range = 100
@export var patrol_speed = 100
@export var chase_speed = 150

# ============ LIFECYCLE ============

func _ready():
	pass

func set_entity(entity_ref):
	"""Set reference to entity using this behavior"""
	entity = entity_ref
	if entity and entity.is_in_group("player"):
		player_ref = entity

func _process(delta):
	"""Update behavior state"""
	if entity == null or entity.is_dead:
		behavior_state = State.DEAD
		return
	
	state_timer -= delta
	_update_behavior(delta)

# ============ BEHAVIOR LOGIC (Override in subclasses) ============

func _update_behavior(delta: float):
	"""
	Override in subclasses to implement behavior logic.
	This is called every frame.
	"""
	pass

func get_movement_direction() -> Vector2:
	"""
	Return movement direction for entity.
	Override in subclasses to implement movement.
	"""
	return Vector2.ZERO

# ============ HELPER METHODS ============

func get_distance_to_player() -> float:
	"""Calculate distance to player"""
	if entity == null or player_ref == null:
		return INF
	
	return entity.global_position.distance_to(player_ref.global_position)

func get_direction_to_player() -> Vector2:
	"""Get unit vector pointing toward player"""
	if entity == null or player_ref == null:
		return Vector2.ZERO
	
	var direction = player_ref.global_position - entity.global_position
	if direction.length() > 0:
		return direction.normalized()
	return Vector2.ZERO

func is_player_in_detection_range() -> bool:
	"""Check if player is within detection range"""
	return get_distance_to_player() <= detection_range

func is_player_in_attack_range() -> bool:
	"""Check if player is within attack range"""
	return get_distance_to_player() <= attack_range

func change_state(new_state: State):
	"""Transition to new behavior state"""
	if new_state == behavior_state:
		return
	
	var old_state = behavior_state
	behavior_state = new_state
	state_timer = 0.0
	emit_signal("behavior_changed", old_state, new_state)

# ============ DEBUG ============

func get_state_name() -> String:
	"""Get human-readable state name"""
	match behavior_state:
		State.IDLE:
			return "IDLE"
		State.PATROL:
			return "PATROL"
		State.CHASE:
			return "CHASE"
		State.ATTACK:
			return "ATTACK"
		State.RETREAT:
			return "RETREAT"
		State.DEAD:
			return "DEAD"
		_:
			return "UNKNOWN"

func get_debug_info() -> String:
	"""Return behavior debug info"""
	var distance = get_distance_to_player()
	var distance_str = "%.1f" % distance if distance < INF else "INF"
	
	return "Behavior: %s | Player Dist: %s | Detection: %d" % [
		get_state_name(),
		distance_str,
		detection_range
	]
