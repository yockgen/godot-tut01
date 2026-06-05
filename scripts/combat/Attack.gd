extends Node
# Base class for all player attacks
# Handles attack execution, cooldowns, and effects

class_name Attack

# ============ SIGNALS ============
signal executed
signal started
signal finished
signal cooldown_changed(percent)

# ============ PROPERTIES ============
@export var attack_name = "Attack"
@export var damage = 10
@export var cooldown = 0.3
@export var animation_name = "attack"
@export var animation_locked_frames = 5  # Frames during which input is blocked

var player_ref = null
var cooldown_timer = 0.0
var is_executing = false
var _last_execution_time = 0.0

# ============ LIFECYCLE ============

func _ready():
	pass

func _process(delta):
	"""Update cooldown"""
	if cooldown_timer > 0:
		cooldown_timer -= delta
		emit_signal("cooldown_changed", 1.0 - (cooldown_timer / cooldown))

# ============ ATTACK EXECUTION ============

func can_execute() -> bool:
	"""Check if attack is ready to execute"""
	return not is_executing and cooldown_timer <= 0

func execute(target_position: Vector2 = Vector2.ZERO) -> bool:
	"""
	Execute the attack.
	Override in subclasses for attack-specific logic.
	Returns true if attack was executed, false if on cooldown.
	"""
	if not can_execute():
		return false
	
	if player_ref == null:
		push_error("Attack %s has no player reference!" % attack_name)
		return false
	
	is_executing = true
	_last_execution_time = Time.get_ticks_msec()
	
	emit_signal("executed")
	emit_signal("started")
	
	_perform_attack(target_position)
	
	return true

func _perform_attack(target_position: Vector2):
	"""
	Override in subclasses to implement attack behavior.
	Called by execute().
	"""
	pass

func finish_execution():
	"""Call when attack animation/effect finishes"""
	is_executing = false
	cooldown_timer = cooldown
	emit_signal("finished")

# ============ COOLDOWN MANAGEMENT ============

func reset_cooldown():
	"""Reset cooldown immediately"""
	cooldown_timer = 0.0
	emit_signal("cooldown_changed", 1.0)

func get_cooldown_percent() -> float:
	"""Return cooldown as percentage (0.0 = ready, 1.0 = full cooldown)"""
	if cooldown == 0:
		return 0.0
	return clamp(cooldown_timer / cooldown, 0.0, 1.0)

# ============ CONFIGURATION ============

func set_player(player):
	"""Set reference to player entity"""
	player_ref = player

func configure(config_dict: Dictionary):
	"""
	Configure attack from dictionary.
	Useful for data-driven attack creation.
	Example: attack.configure({"damage": 20, "cooldown": 0.5})
	"""
	for key in config_dict:
		if key in self:
			set(key, config_dict[key])

# ============ DEBUG ============

func get_debug_info() -> String:
	"""Return attack debug info"""
	return "%s | DMG: %d | CD: %.2f/%.2f" % [
		attack_name,
		damage,
		max(0, cooldown_timer),
		cooldown
	]
