extends Node
class_name StageManager
# Manages stage progression, unlocking, and flow
# Register as autoload in Project > Project Settings > Autoload

# ============ SIGNALS ============
signal stage_started(stage_id, stage_data)
signal stage_completed(stage_id, score)
signal stage_failed(stage_id, reason)
signal unlock_changed(unlocked_stages)

# ============ STATE ============
var stages: Dictionary = {}       # stage_id -> StageResource
var unlocked_stages: Array = []   # [1, 2, ...]
var current_stage_id := 0
var current_stage: StageResource = null

# ============ LIFECYCLE ============

static func get_instance() -> StageManager:
	"""Convenience accessor via group"""
	var nodes = get_tree().get_nodes_in_group("stage_manager")
	if nodes.size() > 0:
		return nodes[0] as StageManager
	return null

func _ready():
	add_to_group("stage_manager")
	_register_stages()
	_load_progress()

func _register_stages():
	"""Register all stages here. Add new stages to this list."""
	# Stage 1: street brawl (current main.tscn)
	_add_stage(preload("res://stages/stage_01.tres"))
	
	# Future stages — uncomment as they're created:
	# _add_stage(preload("res://stages/stage_02.tres"))
	# _add_stage(preload("res://stages/stage_03.tres"))
	# _add_stage(preload("res://stages/stage_04.tres"))

func _add_stage(stage: StageResource):
	"""Register a single stage resource"""
	if stage and not stages.has(stage.stage_id):
		stages[stage.stage_id] = stage
		print("Stage registered: %s (ID: %d)" % [stage.stage_name, stage.stage_id])

# ============ STAGE FLOW ============

func start_stage(stage_id: int) -> bool:
	"""Load and start a stage. Returns true on success."""
	if not stages.has(stage_id):
		push_error("Stage %d not found" % stage_id)
		return false
	if stage_id not in unlocked_stages:
		push_error("Stage %d is locked" % stage_id)
		return false
	
	current_stage_id = stage_id
	current_stage = stages[stage_id]
	
	emit_signal("stage_started", stage_id, current_stage)
	GameManager.reset_game()
	
	# Set difficulty config for this stage
	GameConfig.set_config("stage_difficulty", current_stage.difficulty_multiplier)
	
	# Load the stage's scene
	if current_stage.level_scene:
		var result = get_tree().change_scene_to_packed(current_stage.level_scene)
		if result != OK:
			push_error("Failed to load stage %d scene" % stage_id)
			return false
	else:
		# Fallback to main.tscn for backward compatibility
		var result = get_tree().change_scene_to_file("res://main.tscn")
		if result != OK:
			return false
	
	return true

func restart_stage() -> bool:
	"""Restart the current stage"""
	if current_stage_id <= 0:
		return false
	return start_stage(current_stage_id)

func complete_stage():
	"""Call when the player completes the current stage"""
	if current_stage == null:
		return
	
	var score = GameManager.get_score()
	emit_signal("stage_completed", current_stage_id, score)
	
	# Unlock next stage
	if current_stage.unlock_next_stage:
		var next_id = current_stage_id + 1
		if stages.has(next_id) and next_id not in unlocked_stages:
			unlocked_stages.append(next_id)
			unlocked_stages.sort()
			_save_progress()
			emit_signal("unlock_changed", unlocked_stages.duplicate())
	
	print("Stage %d completed! Score: %d" % [current_stage_id, score])
	current_stage = null
	current_stage_id = 0

func fail_stage(reason: String = ""):
	"""Call when the player fails the current stage"""
	emit_signal("stage_failed", current_stage_id, reason)
	print("Stage %d failed: %s" % [current_stage_id, reason])
	current_stage = null
	current_stage_id = 0

# ============ PROGRESSION ============

func is_stage_unlocked(stage_id: int) -> bool:
	"""Check if a stage is unlocked"""
	return stage_id in unlocked_stages

func unlock_stage(stage_id: int):
	"""Manually unlock a stage (for cheats or special conditions)"""
	if stages.has(stage_id) and stage_id not in unlocked_stages:
		unlocked_stages.append(stage_id)
		unlocked_stages.sort()
		_save_progress()
		emit_signal("unlock_changed", unlocked_stages.duplicate())

func get_stage_count() -> int:
	"""Get total number of registered stages"""
	return stages.size()

func get_stage_list() -> Array:
	"""Get sorted list of all stage IDs"""
	var ids = stages.keys()
	ids.sort()
	return ids

func get_stage_data(stage_id: int) -> StageResource:
	"""Get the StageResource for a given ID"""
	if stages.has(stage_id):
		return stages[stage_id]
	return null

# ============ PERSISTENCE ============

func _save_progress():
	"""Save unlocked stages to user data"""
	var file = FileAccess.open("user://stage_progress.dat", FileAccess.WRITE)
	if file:
		file.store_var(unlocked_stages)

func _load_progress():
	"""Load unlocked stages from user data"""
	if FileAccess.file_exists("user://stage_progress.dat"):
		var file = FileAccess.open("user://stage_progress.dat", FileAccess.READ)
		if file:
			unlocked_stages = file.get_var()
	
	# Always ensure stage 1 is unlocked
	if 1 not in unlocked_stages:
		unlocked_stages.append(1)
		unlocked_stages.sort()
	
	print("Unlocked stages: ", unlocked_stages)

func reset_all_progress():
	"""Reset all stage progress (for testing or new game)"""
	unlocked_stages = [1]
	_save_progress()
	emit_signal("unlock_changed", unlocked_stages.duplicate())
	print("Stage progress reset")

# ============ DEBUG ============

func get_debug_info() -> String:
	"""Return debug info"""
	var current = "None"
	if current_stage:
		current = current_stage.stage_name
	return "Current: %s | Unlocked: %s" % [current, str(unlocked_stages)]
