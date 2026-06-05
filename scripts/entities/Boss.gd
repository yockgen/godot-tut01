extends Enemy
# Base class for boss enemies
# Extends Enemy with boss-specific mechanics

class_name Boss

# ============ SIGNALS ============
signal health_bar_updated(percent)
signal phase_changed(phase_number)

# ============ PROPERTIES ============
@export var boss_name = "Boss"
@export var score_on_hit = 1

var current_phase = 0
var phases = []

# ============ INITIALIZATION ============

func _initialize():
	# Boss-specific stats

	max_health = GameConfig.BOSS_HEALTH
	health = max_health

	collision_damage = GameConfig.BOSS_DAMAGE

	score_on_defeat = 500

func _ready():

	# IMPORTANT:
	# Initialize boss stats first
	_initialize()

	# Call parent ready
	super._ready()

	print(
		"Boss %s initialized with %d HP"
		% [boss_name, max_health]
	)

# ============ HEALTH & DAMAGE ============

func take_damage(damage: int) -> bool:

	# Prevent damage when already dead
	if health <= 0:
		return true

	# Parent damage handling
	var was_fatal = super.take_damage(damage)

	# Only add hit score if still alive
	if not was_fatal:
		GameManager.add_score(
			score_on_hit,
			"Boss hit"
		)

	# Update UI
	emit_signal(
		"health_bar_updated",
		get_health_percent()
	)

	# Check phase transitions only if alive
	if not was_fatal:
		_check_phase_transition()

	return was_fatal

func _check_phase_transition():
	# Override in subclasses
	pass

# ============ PHASE SYSTEM ============

func _enter_phase(phase_num: int):

	# Ignore duplicate transitions
	if phase_num == current_phase:
		return

	current_phase = phase_num

	emit_signal(
		"phase_changed",
		current_phase
	)

	print(
		"Boss %s entered phase %d!"
		% [boss_name, current_phase]
	)

# ============ DEATH ============

func _spawn_death_effect():

	# Parent death effect
	super._spawn_death_effect()

	print(
		"Boss %s defeated!"
		% boss_name
	)

func setGetHit():
	if has_node("SndHitBy"):
		$SndHitBy.play()
	if has_node("Sprite2D"):
		var sprite_node = $Sprite2D
		if sprite_node.material is ShaderMaterial:
			sprite_node.material.set_shader_parameter("whiten", true)
			await get_tree().create_timer(0.3).timeout
			sprite_node.material.set_shader_parameter("whiten", false)

# ============ DEBUG ============

func get_debug_info() -> String:

	return "%s | HP: %d/%d | Phase: %d" % [
		boss_name,
		health,
		max_health,
		current_phase
	]
