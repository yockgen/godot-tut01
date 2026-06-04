extends Control
# Stage selection screen
# Shows a list of stages with lock/unlock status
# Place this scene as the starting screen of the game

# ============ NODE REFERENCES ============
onready var stage_container = $VBoxContainer/StageList
onready var title_label = $VBoxContainer/TitleLabel
onready var stage_button_scene = preload("res://scenes/stages/StageButton.tscn")

# ============ LIFECYCLE ============

func _ready():
	_build_stage_list()

func _build_stage_list():
	"""Populate the stage list from StageManager"""
	var stage_manager = StageManager.get_instance()
	if stage_manager == null:
		push_error("StageManager not found — is it registered as autoload?")
		return
	
	# Clear existing children
	for child in stage_container.get_children():
		child.queue_free()
	
	# Build a button for each registered stage
	for stage_id in stage_manager.get_stage_list():
		var stage_data = stage_manager.get_stage_data(stage_id)
		if stage_data == null:
			continue
		
		var unlocked = stage_manager.is_stage_unlocked(stage_id)
		
		var button = stage_button_scene.instance()
		button.setup(stage_data, unlocked)
		button.connect("pressed", self, "_on_stage_selected", [stage_id])
		stage_container.add_child(button)

# ============ SIGNAL HANDLERS ============

func _on_stage_selected(stage_id: int):
	"""Start the selected stage"""
	var stage_manager = StageManager.get_instance()
	if stage_manager == null:
		return
	
	if stage_manager.is_stage_unlocked(stage_id):
		stage_manager.start_stage(stage_id)
	else:
		print("Stage %d is locked!" % stage_id)

func refresh():
	"""Rebuild the list (call after unlocking new stages)"""
	_build_stage_list()
