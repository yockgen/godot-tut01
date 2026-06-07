extends Entity
# Base class for all enemies (Mob, Boss, etc.)
# Extends Entity with enemy-specific behavior

class_name Enemy

# ============ PROPERTIES ============
@export var score_on_defeat = 150
@export var movement_speed = 100
@export var particleBooming : PackedScene

var _enemy_id = ""
var isGrounded = false

var ai_behavior = null  # RefCounted to AIBehavior, set by spawner
var player_ref = null   # RefCounted to player for targeting

# ============ STATE ENUM ============
# Inherited from Entity

# ============ LIFECYCLE ============

func _ready():
	super._ready()
	# Connect to death signal (safely avoid duplicate connections)
	if not died.is_connected(Callable(self, "_on_enemy_died")):
		var _connect_result = died.connect(Callable(self, "_on_enemy_died"))

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

func _spawn_death_effect():
	"""Override in subclasses to add particles, sounds, etc."""
	# This will be called by Entity._on_death()
	# Subclasses can override for specific effects
	if has_node("GPUParticles2D"):
		var particles = $GPUParticles2D
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
	_enemy_id = id
	# Play hit sound (detach from parent so it isn't destroyed by queue_free)
	if has_node("SndHitBy"):
		var hit_sound = $SndHitBy
		remove_child(hit_sound)
		get_tree().current_scene.add_child(hit_sound)
		hit_sound.play()
		hit_sound.finished.connect(hit_sound.queue_free)
	# Play defeat sound
	if has_node("SoundDown") and not $SoundDown.playing:
		$SoundDown.play()
	
	if particleBooming:
		var _explosion = particleBooming.instantiate()
		_explosion.position = global_position
		_explosion.rotation = global_rotation
		_explosion.emitting = true
		get_tree().current_scene.add_child(_explosion)
	
	call_deferred("queue_free")

func setEnemyGrounded(_id):
	isGrounded = true
	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.play("grounded")
	if has_node("SndExplosion"):
		$SndExplosion.play()
	call_deferred("queue_free")

# ============ DEBUG ============

func get_debug_info() -> String:
	"""Return enemy debug info"""
	var behavior_name = "None"
	if ai_behavior:
		behavior_name = ai_behavior.get_script().get_global_name() if ai_behavior.get_script() else "AIBehavior"
	
	return "%s | HP: %d/%d | Behavior: %s" % [
		name,
		health,
		max_health,
		behavior_name
	]
