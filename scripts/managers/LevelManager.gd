extends Node
# Level manager
# Handles level progression, transitions, and persistence

# ============ SIGNALS ============
signal level_loaded(level_number)
signal level_completed
signal level_failed
signal level_restarted
signal progression_updated(level, progress)

# ============ PROPERTIES ============
var current_level = 1
var max_level = 10  # Extensible
var available_levels = []
var level_scenes = {}  # Map of level_id -> scene_path
var level_progress = {}  # Track player progress per level
var difficulty = 1  # Difficulty multiplier

# ============ LEVEL DEFINITIONS ============

func _ready():
	add_to_group("level_manager")
	_initialize_levels()

func _initialize_levels():
	"""Set up available levels"""
	# TODO: Load from config file or JSON
	# For now, scaffold with level 1 only
	available_levels = [1]
	level_scenes = {
		1: "res://main.tscn"  # Current level
	}
	level_progress = {
		1: {"visited": false, "completed": false, "best_score": 0}
	}

# ============ LEVEL LOADING ============

func load_level(level_number: int) -> bool:
	"""Load a level by number"""
	if level_number not in level_scenes:
		push_error("Level %d not found!" % level_number)
		return false
	
	current_level = level_number
	var level_path = level_scenes[level_number]
	
	print("Loading level %d: %s" % [level_number, level_path])
	GameManager.reset_game()
	emit_signal("level_loaded", level_number)
	
	get_tree().reload_current_scene()
	return true

func restart_level() -> bool:
	"""Restart current level"""
	emit_signal("level_restarted")
	return load_level(current_level)

func next_level() -> bool:
	"""Load next level in sequence"""
	var next_level = current_level + 1
	if next_level > max_level:
		print("All levels completed!")
		return false
	
	return load_level(next_level)

# ============ LEVEL COMPLETION ============

func complete_level(score: int = -1):
	"""Called when player completes level"""
	if score == -1:
		score = GameManager.get_score()
	
	# Update progress
	if current_level in level_progress:
		var progress = level_progress[current_level]
		progress["completed"] = true
		progress["visited"] = true
		progress["best_score"] = max(progress["best_score"], score)
		emit_signal("progression_updated", current_level, progress)
	
	emit_signal("level_completed")
	print("Level %d completed! Score: %d" % [current_level, score])
	
	# Auto-advance to next level (optional)
	yield(get_tree(), "idle_frame")

func fail_level():
	"""Called when player fails level"""
	emit_signal("level_failed")
	print("Level %d failed!" % current_level)

# ============ PROGRESSION TRACKING ============

func get_level_progress(level: int) -> Dictionary:
	"""Get progress data for a level"""
	if level in level_progress:
		return level_progress[level].duplicate()
	return {}

func get_completion_percent() -> float:
	"""Get percent of levels completed"""
	var completed = 0
	for level in level_progress:
		if level_progress[level]["completed"]:
			completed += 1
	
	return float(completed) / float(level_progress.size()) * 100.0

func has_completed_level(level: int) -> bool:
	"""Check if level has been completed"""
	if level in level_progress:
		return level_progress[level]["completed"]
	return false

# ============ DIFFICULTY MANAGEMENT ============

func set_difficulty(new_difficulty: int):
	"""Set difficulty multiplier (1, 2, 3, etc.)"""
	difficulty = clamp(new_difficulty, 1, 10)
	print("Difficulty set to: %d" % difficulty)

func apply_difficulty_scaling(base_value: float) -> float:
	"""Scale a value based on difficulty"""
	return base_value * difficulty

# ============ CONFIGURATION ============

func add_level(level_id: int, scene_path: String):
	"""Dynamically add level"""
	if level_id not in level_scenes:
		available_levels.append(level_id)
		level_scenes[level_id] = scene_path
		level_progress[level_id] = {"visited": false, "completed": false, "best_score": 0}
		max_level = max(max_level, level_id)
		print("Level %d added: %s" % [level_id, scene_path])

# ============ DEBUG ============

func get_debug_info() -> String:
	"""Return level manager debug info"""
	var completed = get_completion_percent()
	return "Level: %d | Progress: %.0f%% | Difficulty: %d" % [
		current_level,
		completed,
		difficulty
	]
