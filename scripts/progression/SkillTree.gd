extends Node
# Skill tree / upgrade system
# Tracks and manages player upgrades and skill progression

# ============ SIGNALS ============
signal skill_unlocked(skill_name)
signal skill_upgraded(skill_name, new_level)
signal skill_points_changed(points)

# ============ PROPERTIES ============
var skill_points = 0
var total_skill_points = 0
var skills = {}  # skill_name -> {level, max_level, effects}

# ============ SKILL DEFINITIONS ============

func _ready():
	add_to_group("skill_tree")
	_initialize_skills()

func _initialize_skills():
	"""Set up available skills"""
	# Placeholder skill definitions
	skills = {
		"health": {
			"level": 0,
			"max_level": 5,
			"effects": {
				"health_bonus": [1, 2, 3, 4, 5]  # Per level
			}
		},
		"speed": {
			"level": 0,
			"max_level": 5,
			"effects": {
				"speed_bonus": [50, 100, 150, 200, 250]
			}
		},
		"damage": {
			"level": 0,
			"max_level": 5,
			"effects": {
				"damage_bonus": [5, 10, 15, 20, 25]
			}
		},
		"dash_cooldown": {
			"level": 0,
			"max_level": 3,
			"effects": {
				"dash_cooldown_reduction": [0.1, 0.2, 0.3]
			}
		}
	}

# ============ SKILL MANAGEMENT ============

func add_skill_points(amount: int):
	"""Add skill points to spend"""
	skill_points += amount
	total_skill_points += amount
	emit_signal("skill_points_changed", skill_points)
	print("Skill points +%d (Total: %d)" % [amount, total_skill_points])

func upgrade_skill(skill_name: String) -> bool:
	if not skills.has(skill_name):
		push_error("Skill '%s' not found!" % skill_name)
		return false
	
	var skill = skills[skill_name]
	
	if skill["level"] >= skill["max_level"]:
		print("Skill '%s' already at max level!" % skill_name)
		return false
	
	if skill_points <= 0:
		print("Not enough skill points!")
		return false
	
	skill["level"] += 1
	skill_points -= 1
	
	emit_signal("skill_upgraded", skill_name, skill["level"])
	emit_signal("skill_points_changed", skill_points)
	
	print("Upgraded '%s' to level %d" % [skill_name, skill["level"]])
	
	return true

# ============ SKILL QUERIES ============

func get_skill_level(skill_name: String) -> int:
	"""Get current level of a skill"""
	if skill_name in skills:
		return skills[skill_name]["level"]
	return 0

func is_skill_maxed(skill_name: String) -> bool:
	"""Check if skill is at max level"""
	if not skills.has(skill_name):
		return false
	
	var skill = skills[skill_name]
	return skill["level"] >= skill["max_level"]

func get_skill_effect(skill_name: String, effect_name: String) -> int:
	"""Get current effect value for a skill"""
	if not skills.has(skill_name):
		return 0
	
	var skill = skills[skill_name]
	var effects = skill["effects"]
	
	if effect_name in effects:
		var effect_values = effects[effect_name]
		var level = skill["level"] - 1  # Convert to 0-indexed
		
		if level >= 0 and level < effect_values.size():
			return effect_values[level]
	
	return 0

# ============ PERSISTENCE ============

func get_skill_data() -> Dictionary:
	"""Export skill data for save/load"""
	var data = {}
	for skill_name in skills:
		data[skill_name] = skills[skill_name]["level"]
	return data

func load_skill_data(data: Dictionary):
	"""Import skill data from save"""
	for skill_name in data:
		if skill_name in skills:
			skills[skill_name]["level"] = min(
				data[skill_name],
				skills[skill_name]["max_level"]
			)

# ============ DEBUG ============

func get_debug_info() -> String:
	"""Return skill tree debug info"""
	var skill_str = ""
	for skill_name in skills:
		var level = skills[skill_name]["level"]
		var max_level = skills[skill_name]["max_level"]
		skill_str += "%s: %d/%d | " % [skill_name, level, max_level]
	
	return "Points: %d | %s" % [skill_points, skill_str.trim_suffix(" | ")]
