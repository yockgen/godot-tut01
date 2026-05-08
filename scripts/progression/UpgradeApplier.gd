extends Node
# Upgrade applier
# Takes skill tree upgrades and applies them to game entities

# ============ PROPERTIES ============
var skill_tree = null
var applied_upgrades = {}  # Track which upgrades are active

# ============ INITIALIZATION ============

func _ready():
	add_to_group("upgrade_applier")
	
	# Get reference to skill tree
	if get_tree().get_nodes_in_group("skill_tree").size() > 0:
		skill_tree = get_tree().get_nodes_in_group("skill_tree")[0]

# ============ UPGRADE APPLICATION ============

func apply_upgrades_to_player(player: PlayerEntity):
	"""Apply all active upgrades to player"""
	if skill_tree == null:
		return
	
	# Health upgrades
	var health_level = skill_tree.get_skill_level("health")
	if health_level > 0:
		var health_bonus = skill_tree.get_skill_effect("health", "health_bonus")
		# Apply health bonus (e.g., increase max_health)
		player.max_health = 1 + health_bonus
	
	# Speed upgrades
	var speed_level = skill_tree.get_skill_level("speed")
	if speed_level > 0:
		var speed_bonus = skill_tree.get_skill_effect("speed", "speed_bonus")
		player.base_speed = GameConfig.PLAYER_SPEED + speed_bonus
		player.current_speed = player.base_speed
	
	# Damage upgrades
	var damage_level = skill_tree.get_skill_level("damage")
	if damage_level > 0:
		var damage_bonus = skill_tree.get_skill_effect("damage", "damage_bonus")
		_apply_damage_bonus_to_attacks(player, damage_bonus)
	
	# Dash cooldown upgrades
	var dash_level = skill_tree.get_skill_level("dash_cooldown")
	if dash_level > 0:
		var cooldown_reduction = skill_tree.get_skill_effect("dash_cooldown", "dash_cooldown_reduction")
		var new_cooldown = GameConfig.PLAYER_DASH_COOLDOWN * (1.0 - cooldown_reduction)
		# Apply to dash system (needs to be wired up in Player.gd)

func apply_upgrades_to_enemy(enemy: Enemy):
	"""Apply difficulty-based upgrades to enemies"""
	if skill_tree == null:
		return
	
	# Difficulty scaling
	var difficulty = LevelManager.difficulty
	enemy.max_health = int(enemy.max_health * difficulty)
	enemy.health = enemy.max_health

func apply_upgrades_to_boss(boss: Boss):
	"""Apply difficulty-based upgrades to bosses"""
	if skill_tree == null:
		return
	
	# Boss health scales more aggressively with difficulty
	var difficulty = LevelManager.difficulty
	boss.max_health = int(boss.max_health * (1 + difficulty * 0.5))
	boss.health = boss.max_health

# ============ HELPER METHODS ============

func _apply_damage_bonus_to_attacks(player, damage_bonus: int):
	"""
	Apply damage bonus to player's attacks.
	This requires attacks to be stored in player for reference.
	"""
	# To be implemented when player attack system is integrated
	print("Damage bonus %d would be applied to attacks" % damage_bonus)

# ============ UPGRADE QUERIES ============

func get_applied_upgrades() -> Array:
	"""Get list of active upgrades"""
	var active = []
	if skill_tree == null:
		return active
	
	for skill_name in skill_tree.skills:
		var level = skill_tree.get_skill_level(skill_name)
		if level > 0:
			active.append({
				"name": skill_name,
				"level": level
			})
	
	return active

# ============ DEBUG ============

func get_debug_info() -> String:
	"""Return upgrade applier debug info"""
	var upgrades = get_applied_upgrades()
	if upgrades.empty():
		return "No upgrades applied"
	
	var info = ""
	for upgrade in upgrades:
		info += "%s (L%d) | " % [upgrade["name"], upgrade["level"]]
	
	return info.trim_suffix(" | ")
