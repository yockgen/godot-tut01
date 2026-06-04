extends Resource
class_name EnemyPoolEntry
# Defines one type of enemy in a stage's spawn pool
# Attach an array of these to StageResource.enemy_pools

export var enemy_scene: PackedScene  # The enemy scene to spawn
export var weight := 1.0             # Higher = more likely to spawn
export var min_delay := 0.0          # Seconds before this type can start spawning
export var max_count := -1           # -1 = unlimited
