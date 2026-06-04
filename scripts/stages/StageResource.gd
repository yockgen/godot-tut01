extends Resource
class_name StageResource
# Stage definition resource
# Create .tres files from this to define each stage
# Usage: In Godot editor, create new Resource > StageResource, fill fields, save as .tres

# === IDENTIFICATION ===
export var stage_id := 1
export var stage_name := "Stage 1"
export var stage_description := ""

# === SCENE ===
export var level_scene: PackedScene  # The .tscn file for this stage's environment

# === ENEMY CONFIG ===
export var spawn_rate := 1.5        # Seconds between spawns
export var max_concurrent_enemies := 5
export var use_boss := false
export var boss_scene: PackedScene

# === DIFFICULTY ===
export var difficulty_multiplier := 1.0
export var enemy_health_multiplier := 1.0
export var enemy_speed_multiplier := 1.0

# === VICTORY CONDITIONS ===
export var target_score := 0        # 0 = disabled
export var defeat_boss_to_win := false
export var survival_time := 0.0    # 0 = disabled; survive this many seconds

# === REWARDS ===
export var base_score_reward := 500
export var unlock_next_stage := true
