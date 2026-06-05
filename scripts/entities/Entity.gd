extends Node2D
# Base class for all combat entities (Player, Mob, Boss)
# Provides unified interface for health, state, and damage handling

class_name Entity

# ============ SIGNALS ============
signal health_changed(old_value, new_value)
signal died
signal state_changed(old_state, new_state)
signal hit_received(damage_amount)

# ============ PROPERTIES ============
@export var max_health = 1
@export var collision_damage = 10  # Damage dealt to player on collision

var health = 1: get = _get_health, set = _set_health
var current_state = State.NORMAL
var is_dead = false

# ============ STATE ENUM ============
enum State {
	NORMAL,      # Regular movement/behavior
	FREEZE,      # Knocked back/stunned (invincible)
	BULLET_TIME, # Slow motion state
	DEAD         # Dead/dying
}

# ============ LIFECYCLE ============

func _ready():
	health = max_health
	call_deferred("_initialize")

func _initialize():
	"""Override this in subclasses for per-entity initialization"""
	pass

# ============ HEALTH & DAMAGE ============

func take_damage(damage: int) -> bool:
	"""
	Apply damage to entity. Returns true if entity died.
	Override in subclasses for special damage handling (e.g., shield effects).
	"""
	if is_dead:
		return false
	
	var _old_health = health
	health -= damage
	emit_signal("hit_received", damage)
	
	if health <= 0:
		health = 0
		_on_death()
		return true
	
	return false

func heal(amount: int):
	"""Restore health up to max"""
	var old_health = health
	health = min(health + amount, max_health)
	if health != old_health:
		emit_signal("health_changed", old_health, health)

func _set_health(value: int):
	"""Private setter with signal emission"""
	if value == health:
		return
	var old_health = health
	health = value
	emit_signal("health_changed", old_health, health)

func _get_health() -> int:
	"""Private getter"""
	return health

# ============ STATE MANAGEMENT ============

func change_state(new_state: State) -> bool:
	"""
	Transition to new state. Returns true if transition was successful.
	Override in subclasses for state-specific logic.
	"""
	if new_state == current_state or is_dead:
		return false
	
	var old_state = current_state
	current_state = new_state
	emit_signal("state_changed", old_state, new_state)
	return true

func get_state() -> State:
	"""Return current state"""
	return current_state

func get_state_name() -> String:
	"""Return human-readable state name"""
	match current_state:
		State.NORMAL:
			return "NORMAL"
		State.FREEZE:
			return "FREEZE"
		State.BULLET_TIME:
			return "BULLET_TIME"
		State.DEAD:
			return "DEAD"
		_:
			return "UNKNOWN"

# ============ DEATH HANDLING ============

func _on_death():
	"""Called when health reaches 0. Override in subclasses for death effects."""
	is_dead = true
	var _discard = change_state(State.DEAD)
	emit_signal("died")
	_spawn_death_effect()
	await get_tree().process_frame
	queue_free()

func _spawn_death_effect():
	"""Override in subclasses to add particles, sounds, etc."""
	pass

# ============ COLLISION HANDLING ============

func on_collision_with_entity(_other: Entity):
	"""
	Called when this entity collides with another entity.
	Override in subclasses for custom collision behavior.
	"""
	pass

# ============ UTILITY ============

func is_alive() -> bool:
	return not is_dead and health > 0

func get_health_percent() -> float:
	"""Return health as percentage (0.0 to 1.0)"""
	if max_health == 0:
		return 0.0
	return float(health) / float(max_health)
