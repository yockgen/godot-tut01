extends Node
# Animation controller for player
# Manages animation state and input locking

class_name AnimationController

# ============ SIGNALS ============
signal animation_started(anim_name)
signal animation_finished(anim_name)
signal animation_locked_changed(is_locked)

# ============ PROPERTIES ============
var animated_sprite = null
var locked_animations = []  # Animations that lock input
var current_animation = ""
var is_locked = false
var lock_until_frame = 0
var current_frame = 0

# ============ INITIALIZATION ============

func _ready():
	if not animated_sprite:
		push_error("AnimationController: animated_sprite not set!")
		return
	
	# Default animations that lock input
	locked_animations = ["swing", "dance", "open_arm", "fire_stand"]
	
	# Connect to sprite signals
	animated_sprite.connect("animation_finished", self, "_on_animation_finished")

func _process(_delta):
	"""Check for animation locks"""
	if not animated_sprite or not animated_sprite.is_playing():
		_update_lock_status(false)
		return
	
	current_animation = animated_sprite.animation
	current_frame = animated_sprite.frame
	
	# Check if we're in a locked animation
	var frame_count = animated_sprite.frames.get_frame_count(current_animation)
	
	# Lock if animation is in the locked list and not on last frame
	if current_animation in locked_animations:
		var should_lock = current_frame < frame_count - 1
		_update_lock_status(should_lock)
	else:
		_update_lock_status(false)

# ============ ANIMATION CONTROL ============

func play_animation(animation_name: String, force_restart: bool = false) -> bool:
	"""
	Play an animation.
	Returns true if animation was played, false if already playing and force_restart is false.
	"""
	if not animated_sprite:
		return false
	
	if animated_sprite.animation == animation_name and not force_restart:
		if not animated_sprite.is_playing():
			animated_sprite.play()
		return false
	
	animated_sprite.animation = animation_name
	animated_sprite.play()
	emit_signal("animation_started", animation_name)
	
	# Update lock status
	if animation_name in locked_animations:
		_update_lock_status(true)
	
	return true

func stop_animation():
	"""Stop current animation"""
	if animated_sprite:
		animated_sprite.stop()
		_update_lock_status(false)

func set_animation_frame(frame: int):
	"""Set current animation frame"""
	if animated_sprite:
		animated_sprite.frame = frame

func get_current_animation() -> String:
	"""Get current animation name"""
	if animated_sprite:
		return animated_sprite.animation
	return ""

func get_current_frame() -> int:
	"""Get current animation frame"""
	if animated_sprite:
		return animated_sprite.frame
	return 0

# ============ ANIMATION LOCKING ============

func is_input_locked() -> bool:
	"""Check if input is locked due to animation"""
	return is_locked

func lock_input(duration: float = -1.0):
	"""
	Manually lock input.
	If duration > 0, unlock after that many seconds.
	"""
	_update_lock_status(true)
	
	if duration > 0:
		yield(get_tree().create_timer(duration), "timeout")
		if is_locked:
			_update_lock_status(false)

func unlock_input():
	"""Unlock input immediately"""
	_update_lock_status(false)

func _update_lock_status(locked: bool):
	"""Update lock status and emit signal if changed"""
	if locked != is_locked:
		is_locked = locked
		emit_signal("animation_locked_changed", is_locked)

# ============ SIGNAL HANDLERS ============

func _on_animation_finished(anim_name: String):
	"""Called when animation finishes"""
	emit_signal("animation_finished", anim_name)
	_update_lock_status(false)

# ============ CONFIGURATION ============

func add_locked_animation(anim_name: String):
	"""Add animation to locked list"""
	if anim_name not in locked_animations:
		locked_animations.append(anim_name)

func remove_locked_animation(anim_name: String):
	"""Remove animation from locked list"""
	if anim_name in locked_animations:
		locked_animations.erase(anim_name)

func set_locked_animations(anim_list: Array):
	"""Replace locked animations list"""
	locked_animations = anim_list.duplicate()

# ============ DEBUG ============

func get_debug_info() -> String:
	"""Return animation controller debug info"""
	return "Animation: %s [%d] | Locked: %s" % [
		current_animation,
		current_frame,
		is_locked
	]
