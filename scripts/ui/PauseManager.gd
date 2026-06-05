extends Node
# Pause system manager
# Centralized pause state and UI management

# ============ SIGNALS ============
signal pause_requested
signal resumed
signal pause_screen_shown
signal pause_screen_hidden

# ============ PROPERTIES ============
var is_paused = false
# ============ LIFECYCLE ============

func _ready():
	add_to_group("pause_manager")
	set_process_input(true)

func _input(event):
	"""Handle pause input"""
	if event.is_action_pressed("ui_cancel"):  # ESC key
		toggle_pause()
		get_viewport().set_input_as_handled()

# ============ PAUSE CONTROL ============

func toggle_pause():
	"""Toggle pause state"""
	if is_paused:
		resume_game()
	else:
		pause_game()

func pause_game():
	"""Pause game and show UI"""
	if is_paused:
		return
	
	is_paused = true
	GameManager.set_pause(true)
	emit_signal("pause_requested")
	_show_pause_screen()
	print("Game paused")

func resume_game():
	"""Resume game and hide UI"""
	if not is_paused:
		return
	
	is_paused = false
	GameManager.set_pause(false)
	emit_signal("resumed")
	_hide_pause_screen()
	print("Game resumed")

# ============ UI MANAGEMENT ============

func _show_pause_screen():
	"""Show pause menu UI"""
	emit_signal("pause_screen_shown")
	# UI implementation done in PauseCtrl.tscn refactor

func _hide_pause_screen():
	"""Hide pause menu UI"""
	emit_signal("pause_screen_hidden")
	# UI implementation done in PauseCtrl.tscn refactor

# ============ UTILITY ============

func is_game_paused() -> bool:
	"""Query pause state"""
	return is_paused

func get_debug_info() -> String:
	"""Return pause debug info"""
	return "Paused: %s" % is_paused
