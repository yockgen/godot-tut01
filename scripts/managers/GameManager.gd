extends Node
# Game state manager singleton
# Autoload this in Project Settings > Autoload as "GameManager"

class_name GameManager

# ============ SIGNALS ============
signal score_changed(new_score)
signal pause_toggled(is_paused)
signal game_over
signal level_completed
signal entity_defeated(entity_name)

# ============ STATE ============
var score = 0
var is_paused = false
var current_level = 1
var game_over_flag = false

# Audio references
var audio_manager = null

# ============ LIFECYCLE ============

func _ready():
	# Prevent duplicate managers
	if get_tree().get_nodes_in_group("game_manager").size() > 1:
		queue_free()
		return
	
	add_to_group("game_manager")
	set_process_mode(PROCESS_MODE_ALWAYS)  # Keep processing even when paused
	print("GameManager initialized")

# ============ SCORING ============

func add_score(amount: int, reason: String = ""):
	"""Add or subtract score"""
	score += amount
	emit_signal("score_changed", score)
	if reason:
		print("Score %+d (%s) - Total: %d" % [amount, reason, score])

func get_score() -> int:
	"""Get current score"""
	return score

func reset_score():
	"""Reset score to 0"""
	score = 0
	emit_signal("score_changed", score)

# ============ PAUSE SYSTEM ============

func toggle_pause() -> bool:
	"""Toggle pause state globally"""
	set_pause(not is_paused)
	return is_paused

func set_pause(paused: bool):
	"""Set pause state explicitly"""
	if paused == is_paused:
		return
	
	is_paused = paused
	get_tree().paused = paused
	emit_signal("pause_toggled", is_paused)
	print("Game %s" % ("paused" if is_paused else "resumed"))

func is_game_paused() -> bool:
	"""Check if game is paused"""
	return is_paused

# ============ GAME STATE ============

func trigger_game_over():
	"""Trigger game over state"""
	if game_over_flag:
		return
	
	game_over_flag = true
	set_pause(true)
	emit_signal("game_over")
	print("GAME OVER")

func reset_game():
	"""Reset game state for new level/restart"""
	game_over_flag = false
	score = 0
	emit_signal("score_changed", score)
	set_pause(false)

func complete_level():
	"""Signal level completion"""
	emit_signal("level_completed")
	print("Level %d completed!" % current_level)

# ============ ENTITY EVENTS ============

func on_entity_defeated(entity_name: String):
	"""Called when any entity dies"""
	emit_signal("entity_defeated", entity_name)

# ============ AUDIO MANAGEMENT ============

func play_sfx(audio_name: String, position: Vector2 = Vector2.ZERO):
	"""Play sound effect by name"""
	if audio_manager:
		audio_manager.play_sfx(audio_name, position)

func set_master_volume(volume_db: float):
	"""Set master volume"""
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), false)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), volume_db)

# ============ DEBUG ============

func get_debug_info() -> String:
	"""Return debug information"""
	return "Score: %d | Paused: %s | Level: %d | GameOver: %s" % [
		score,
		is_paused,
		current_level,
		game_over_flag
	]
