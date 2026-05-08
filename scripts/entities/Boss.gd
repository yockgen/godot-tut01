extends Enemy
# Base class for boss enemies
# Extends Enemy with boss-specific mechanics: phases, health bar, multiple hits

class_name Boss

# ============ SIGNALS ============
signal health_bar_updated(percent)
signal phase_changed(phase_number)

# ============ PROPERTIES ============
export var boss_name = "Boss"
export var score_on_hit = 1
var current_phase = 0
var phases = []  # Array of phase objects (implement per boss)

# ============ INITIALIZATION ============

func _initialize():
	"""Set up boss-specific stats"""
	max_health = GameConfig.BOSS_HEALTH
	health = max_health
	collision_damage = GameConfig.BOSS_DAMAGE
	score_on_defeat = 500  # Bosses worth more than regular enemies

func _ready():
	._ready()
	print("Boss %s initialized with %d HP" % [boss_name, max_health])

# ============ HEALTH & DAMAGE ============

func take_damage(damage: int) -> bool:
	"""Override to add phase transition checks"""
	var died = .take_damage(damage)
	
	# Add score for hitting boss
	GameManager.add_score(score_on_hit, "Boss hit")
	
	# Update health bar
	emit_signal("health_bar_updated", get_health_percent())
	
	# Check for phase transition
	_check_phase_transition()
	
	return died

func _check_phase_transition():
	"""Override in subclasses to implement phase logic"""
	# Example:
	# if health <= max_health / 2 and current_phase == 0:
	#     _enter_phase(1)
	pass

# ============ PHASE SYSTEM ============

func _enter_phase(phase_num: int):
	"""Transition to new phase"""
	if phase_num == current_phase:
		return
	
	current_phase = phase_num
	emit_signal("phase_changed", current_phase)
	print("Boss %s entered phase %d!" % [boss_name, current_phase])
	
	# Override in subclasses to implement phase behavior

# ============ DEATH ============

func _spawn_death_effect():
	"""Boss death is more dramatic"""
	._spawn_death_effect()
	# Add custom boss death effects
	print("Boss %s defeated!" % boss_name)

# ============ DEBUG ============

func get_debug_info() -> String:
	"""Return boss debug info"""
	return "%s | HP: %d/%d | Phase: %d" % [
		boss_name,
		health,
		max_health,
		current_phase
	]
