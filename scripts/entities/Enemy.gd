extends Entity
# Base class for all enemies (Mob, Boss, etc.)
# Extends Entity with enemy-specific behavior

class_name Enemy

# ============ PROPERTIES ============
export var score_on_defeat = 150
export var movement_speed = 100
export var particleBooming : PackedScene

var enemy = ""
var isGrounded = false

var ai_behavior = null  # Reference to AIBehavior, set by spawner
var player_ref = null   # Reference to player for targeting

# ============ STATE ENUM ============
# Inherited from Entity

# ============ LIFECYCLE ============

func _ready():
	._ready()
	# Connect to death signal
	var _connect_result = connect("died", self, "_on_enemy_died")

func _initialize():
	"""Set up enemy-specific initialization"""
	max_health = GameConfig.MOB_HEALTH
	health = max_health
	collision_damage = GameConfig.MOB_DAMAGE
	add_to_group("enemy")

# ============ HEALTH & DAMAGE ============

func take_damage(damage: int) -> bool:
	"""
	Apply damage to entity. Returns true if entity died.
	Override in subclasses for special damage handling (e.g., shield effects).
	"""
	if is_dead:
		return false
	
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

func change_state(new_state: int) -> bool:
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

func get_state() -> int:
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
	var _change_state_result = change_state(State.DEAD)
	emit_signal("died")
	_spawn_death_effect()
	yield(get_tree(), "idle_frame")
	queue_free()

func _spawn_death_effect():
	"""Override in subclasses to add particles, sounds, etc."""
	# This will be called by Entity._on_death()
	# Subclasses can override for specific effects
	if has_node("Particles2D"):
		var particles = $Particles2D
		particles.emitting = true

# ============ COLLISION HANDLING ============

func on_collision_with_entity(other):
	"""
	Called when this entity collides with another entity.
	Override in subclasses for custom collision behavior.
	"""
	if other.is_in_group("player"):
		# Enemy hit player
		other.take_damage(collision_damage)

# ============ UTILITY ============

func is_alive() -> bool:
	return not is_dead and health > 0

func get_health_percent() -> float:
	"""Return health as percentage (0.0 to 1.0)"""
	if max_health == 0:
		return 0.0
	return float(health) / float(max_health)

# ============ MOVEMENT ============

func set_ai_behavior(behavior):
	"""Set the AI behavior for this enemy"""
	ai_behavior = behavior
	if behavior:
		behavior.set_entity(self)

func get_movement_direction() -> Vector2:
	"""Query AI behavior for movement direction"""
	if ai_behavior:
		return ai_behavior.get_movement_direction()
	return Vector2.ZERO

# ============ SIGNALS & EVENTS ============

func _on_enemy_died():
	"""Handle death event"""
	GameManager.add_score(score_on_defeat, "Enemy defeated")
	GameManager.on_entity_defeated(name)
	print("Enemy %s defeated! Score +%d" % [name, score_on_defeat])

func setEnemyDown(id):
	enemy = id
	if has_node("SoundDown") and not $SoundDown.playing:
		$SoundDown.play()
	
	if particleBooming:
		var _explosion = particleBooming.instance()
		_explosion.position = global_position
		_explosion.rotation = global_rotation
		_explosion.emitting = true
		get_tree().current_scene.add_child(_explosion)
	
	call_deferred("queue_free")

func setEnemyGrounded(_id):
	isGrounded = true
	if has_node("AnimatedSprite"):
		$AnimatedSprite.play("grounded")
	if has_node("SndExplosion"):
		$SndExplosion.play()
	call_deferred("queue_free")

# ============ DEBUG ============

func get_debug_info() -> String:
	"""Return enemy debug info"""
	var behavior_name = "None"
	if ai_behavior:
		behavior_name = ai_behavior.get_class()
	
	return "%s | HP: %d/%d | Behavior: %s" % [
		name,
		health,
		max_health,
		behavior_name
	]
