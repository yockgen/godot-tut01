extends Entity
# Player entity class
# Extends Entity with player-specific mechanics: attacks, dash, invincibility states

class_name PlayerEntity

# ============ SIGNALS ============
signal dash_performed
signal attacked
signal invincibility_started(duration)
signal invincibility_ended
signal bullet_time_started(duration)
signal bullet_time_ended

# ============ PROPERTIES ============
export var base_speed = 400
export var max_dashes = 1

var current_speed = base_speed
var current_dash_count = 0
var is_dashing = false
var dash_timer = 0.0
var invincibility_timer = 0.0
var bullet_time_timer = 0.0

# Node references (to be set up by actual Player implementation)
var animated_sprite = null
var collision_shape = null
var attack_node = null

# ============ LIFECYCLE ============

func _initialize():
	"""Set up player-specific stats"""
	max_health = 1  # Player usually has 1 HP in this game
	health = max_health
	add_to_group("player")
	print("PlayerEntity initialized")

func _ready():
	._ready()
	current_speed = base_speed

func _process(delta):
	"""Update player state"""
	if is_dead or GameManager.is_game_paused():
		return
	
	_update_invincibility(delta)
	_update_bullet_time(delta)
	_update_dash(delta)

# ============ DAMAGE & INVINCIBILITY ============

func take_damage(damage: int) -> bool:
	"""Override to handle player-specific damage logic"""
	if current_state == State.FREEZE:
		# Already invincible
		return false
	
	var died = .take_damage(damage)
	GameManager.add_score(GameConfig.SCORE_PLAYER_HIT, "Player hit")
	
	if not died:
		start_invincibility(GameConfig.PLAYER_INVINCIBILITY_DURATION)
	
	return died

func start_invincibility(duration: float):
	"""Start invincibility period (freeze state)"""
	if current_state == State.FREEZE:
		return
	
	change_state(State.FREEZE)
	invincibility_timer = duration
	emit_signal("invincibility_started", duration)
	
	# Disable collision
	if collision_shape:
		collision_shape.set_deferred("disabled", true)

func _update_invincibility(delta: float):
	"""Update invincibility timer"""
	if current_state != State.FREEZE:
		return
	
	invincibility_timer -= delta
	
	if invincibility_timer <= 0:
		current_state = State.NORMAL
		if collision_shape:
			collision_shape.set_deferred("disabled", false)
		emit_signal("invincibility_ended")

# ============ BULLET TIME / DODGE SYSTEM ============

func enter_bullet_time(duration: float):
	"""Enter slow-motion bullet time state"""
	if current_state == State.BULLET_TIME:
		return
	
	change_state(State.BULLET_TIME)
	bullet_time_timer = duration
	current_speed = base_speed * GameConfig.PLAYER_BULLET_TIME_DASH_MULTIPLIER
	emit_signal("bullet_time_started", duration)

func _update_bullet_time(delta: float):
	"""Update bullet time state"""
	if current_state != State.BULLET_TIME:
		return
	
	bullet_time_timer -= delta
	
	if bullet_time_timer <= 0:
		exit_bullet_time()

func exit_bullet_time():
	"""Exit bullet time and return to normal state"""
	current_state = State.NORMAL
	current_speed = base_speed
	emit_signal("bullet_time_ended")

# ============ DASH / MOVEMENT ============

func perform_dash():
	"""Execute a dash move"""
	if is_dashing or current_dash_count >= max_dashes:
		return false
	
	is_dashing = true
	dash_timer = GameConfig.PLAYER_DASH_DURATION
	current_dash_count += 1
	
	# Apply speed boost
	if current_state == State.BULLET_TIME:
		current_speed = base_speed * GameConfig.PLAYER_BULLET_TIME_DASH_MULTIPLIER
	else:
		current_speed = base_speed * GameConfig.PLAYER_NORMAL_DASH_MULTIPLIER
	
	emit_signal("dash_performed")
	return true

func _update_dash(delta: float):
	"""Update dash state"""
	if not is_dashing:
		return
	
	dash_timer -= delta
	
	if dash_timer <= 0:
		is_dashing = false
		current_speed = base_speed
		if current_state != State.BULLET_TIME:
			current_speed = base_speed

func reset_dash_count():
	"""Reset dash count (called per turn/level)"""
	current_dash_count = 0

func get_current_speed() -> float:
	"""Get current movement speed (considering dash, states, etc.)"""
	return current_speed

# ============ ATTACKS ============

func perform_attack(attack_index: int = 0):
	"""Execute attack at given index"""
	emit_signal("attacked")
	# Attack system will be implemented in Phase 2

# ============ COLLISION HANDLING ============

func on_collision_with_entity(other: Entity):
	"""Handle collision with other entities"""
	if other.is_in_group("enemy"):
		take_damage(other.collision_damage)

# ============ DEBUG ============

func get_debug_info() -> String:
	"""Return player debug info"""
	return "Player | HP: %d | State: %s | Speed: %.1f | Dash: %d/%d" % [
		health,
		get_state_name(),
		current_speed,
		current_dash_count,
		max_dashes
	]
