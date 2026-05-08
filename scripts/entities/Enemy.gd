extends Entity
# Base class for all enemies (Mob, Boss, etc.)
# Extends Entity with enemy-specific behavior

class_name Enemy

# ============ PROPERTIES ============
export var score_on_defeat = 150
export var movement_speed = 100

var ai_behavior = null  # Reference to AIBehavior, set by spawner
var player_ref = null   # Reference to player for targeting

# ============ LIFECYCLE ============

func _initialize():
	"""Set up enemy-specific initialization"""
	max_health = GameConfig.MOB_HEALTH
	health = max_health
	collision_damage = GameConfig.MOB_DAMAGE

func _ready():
	._ready()
	# Connect to death signal
	connect("died", self, "_on_enemy_died")

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

# ============ DAMAGE & DEATH ============

func _spawn_death_effect():
	"""Spawn death particles and sounds"""
	# This will be called by Entity._on_death()
	# Subclasses can override for specific effects
	if has_node("Particles2D"):
		var particles = $Particles2D
		particles.emitting = true

# ============ SIGNALS & EVENTS ============

func _on_enemy_died():
	"""Handle death event"""
	GameManager.add_score(score_on_defeat, "Enemy defeated")
	GameManager.on_entity_defeated(name)
	print("Enemy %s defeated! Score +%d" % [name, score_on_defeat])

# ============ COLLISION ============

func on_collision_with_entity(other: Entity):
	"""Handle collision with another entity"""
	if other.is_in_group("player"):
		# Enemy hit player
		other.take_damage(collision_damage)

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
