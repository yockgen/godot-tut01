extends Node
# Centralized game balance and configuration
# Autoload this as singleton: Project > Project Settings > Autoload

# ============ PLAYER CONSTANTS ============
const PLAYER_SPEED = 400
const PLAYER_DASH_COOLDOWN = 0.5  # seconds
const PLAYER_DASH_DURATION = 0.15  # seconds (frames: 15 at 100fps)
const PLAYER_INVINCIBILITY_DURATION = 1.0  # seconds
const PLAYER_BLINK_SPEED = 0.1  # blink animation speed during freeze

# Damage and boost multipliers
const PLAYER_NORMAL_DASH_MULTIPLIER = 4.0
const PLAYER_BULLET_TIME_DASH_MULTIPLIER = 16.0

# Attack cooldowns
const ATTACK_BASIC_COOLDOWN = 0.3
const ATTACK_FINISHER01_COOLDOWN = 1.0
const ATTACK_FINISHER02_COOLDOWN = 1.2

# ============ MOB/ENEMY CONSTANTS ============
const MOB_SPAWN_RATE = 1.5  # seconds between spawns
const MOB_HEALTH = 1
const MOB_SPEED = 100
const MOB_DAMAGE = 10
const MOB_SCORE_VALUE = 150

# ============ BOSS CONSTANTS ============
const BOSS_HEALTH = 50
const BOSS_DAMAGE = 15
const BOSS_SCORE_VALUE = 1

# ============ SCORING CONSTANTS ============
const SCORE_MOB_DEFEAT = 150
const SCORE_BOSS_HIT = 1
const SCORE_MINION_HIT = 150
const SCORE_PLAYER_HIT = -100
const SCORE_ENEMY_REACH_GROUND = -150

# ============ EFFECTS & PARTICLES ============
const PARTICLE_LIFETIME = 10.0  # seconds (should be lower, based on animation)
const ANIMATION_SPEED_MULTIPLIER = 1.0

# ============ PHYSICS ============
const GRAVITY = 800  # for RigidBody2D entities

# ============ UTILITY METHODS ============

func get_config(key: String, default_value = null):
	"""Generic config getter for flexibility"""
	if has_meta(key):
		return get_meta(key)
	return default_value

func set_config(key: String, value):
	"""Generic config setter for runtime adjustments"""
	set_meta(key, value)
