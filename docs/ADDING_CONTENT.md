# How to Add Game Content

Quick reference for adding new attacks, enemies, levels, and more without modifying existing code.

---

## Adding an Attack (20 minutes)

### Step 1: Create Attack Class
Create `scripts/combat/PowerAttack.gd`:

```gdscript
extends Attack
class_name PowerAttack

func _ready():
	attack_name = "Power Attack"
	damage = 30
	cooldown = 1.2
	animation_name = "power_attack"

func _perform_attack(target_position: Vector2):
	if player_ref == null:
		return
	
	# Play animation
	if player_ref.has_node("AnimatedSprite"):
		var sprite = player_ref.get_node("AnimatedSprite")
		sprite.animation = animation_name
		sprite.play()
	
		# Wait for animation
	var length = 0.8  # Adjust to match animation duration
	await get_tree().create_timer(length).timeout
	
	# Deal damage (will be integrated with hitbox system in Phase 2)
	print("Power Attack executed!")
	
	finish_execution()
```

### Step 2: Add to Player
When player attack system is integrated, add to player's attacks array:
```gdscript
attacks.append(PowerAttack.new())
attacks[attacks.size()-1].set_player(self)
```

### Step 3: Test
Call in input handler:
```gdscript
if Input.is_action_just_pressed("attack3"):
	attacks[2].execute()
```

---

## Adding an Enemy Type (30 minutes)

### Step 1: Create Enemy Class
Create `scripts/entities/BossGolem.gd`:

```gdscript
extends Boss
class_name BossGolem

func _initialize():
	boss_name = "Stone Golem"
	max_health = 100
	health = max_health
	collision_damage = 20
	score_on_defeat = 1000

func _ready():
	._ready()
	print("Boss Golem spawned!")

func _check_phase_transition():
	# Simple two-phase boss
	if health <= max_health / 2 and current_phase == 0:
		_enter_phase(1)

func _enter_phase(phase_num: int):
	.._enter_phase(phase_num)
	match phase_num:
		1:
			print("Golem enters enraged phase!")
			collision_damage = 30  # Hits harder
```

### Step 2: (Optional) Create Behavior
Create `scripts/ai/GolemBehavior.gd`:

```gdscript
extends AIBehavior
class_name GolemBehavior

func _update_behavior(delta):
	match behavior_state:
		State.IDLE:
			if is_player_in_detection_range():
				change_state(State.CHASE)
		State.CHASE:
			if is_player_in_attack_range():
				change_state(State.ATTACK)
			elif not is_player_in_detection_range():
				change_state(State.IDLE)
		State.ATTACK:
			state_timer -= delta
			if state_timer <= 0:
				# Attack player
				if is_player_in_attack_range():
					state_timer = 1.0  # Attack cooldown
				else:
					change_state(State.CHASE)

func get_movement_direction() -> Vector2:
	match behavior_state:
		State.CHASE:
			return get_direction_to_player() * chase_speed
		State.ATTACK:
			return get_direction_to_player() * 50  # Slow advance during attack
		_:
			return Vector2.ZERO
```

### Step 3: Spawn in Scene
In main.gd or level script:
```gdscript
var boss = BossGolem.new()
boss.set_ai_behavior(GolemBehavior.new())
add_child(boss)
boss.global_position = Vector2(960, 300)  # Center of screen
```

---

## Adding an Enemy Spawn Pattern (20 minutes)

### Example: Spawn waves of enemies

Edit `main.gd` spawn logic:

```gdscript
var wave_number = 0
var enemies_in_wave = 3

func _on_MobTimer_timeout():
	if get_tree().get_nodes_in_group("enemy").size() < 5:
		for i in range(enemies_in_wave):
			spawn_mob()
	
	# Increase difficulty after 20 spawns
	if spawn_count >= 20:
		wave_number += 1
		enemies_in_wave = 3 + wave_number
		spawn_count = 0

func spawn_mob():
	var mob = Mob.instance()
	mob.add_to_group("enemy")
	add_child(mob)
	# Set AI based on difficulty
	var behavior = PatrolBehavior.new() if wave_number < 3 else ChaseBehavior.new()
	behavior.set_entity(mob)
```

---

## Adding a Level (15 minutes)

### Step 1: Create Level Scene
1. In Godot editor, duplicate `main.tscn` → `level_2.tscn`
2. Modify background, enemy spawn positions, etc.
3. Save in `res://levels/`

### Step 2: Register in LevelManager
Edit `scripts/managers/LevelManager.gd`:

```gdscript
func _initialize_levels():
	available_levels = [1, 2, 3]
	level_scenes = {
		1: "res://main.tscn",
		2: "res://levels/level_2.tscn",
		3: "res://levels/level_3.tscn"
	}
	
	for level_id in level_scenes:
		if level_id not in level_progress:
			level_progress[level_id] = {"visited": false, "completed": false, "best_score": 0}
```

### Step 3: Load Level
```gdscript
LevelManager.load_level(2)  # Load level 2
LevelManager.next_level()   # Auto-advance to next
```

---

## Adjusting Game Balance (5 minutes)

All balance values are in `scripts/config/GameConfig.gd`.

### Example: Make player faster
```gdscript
# In GameConfig.gd
const PLAYER_SPEED = 500  # Was 400
```

### Example: Increase enemy damage
```gdscript
# In GameConfig.gd
const MOB_DAMAGE = 20  # Was 10
```

### Example: Adjust attack cooldowns
```gdscript
# In GameConfig.gd
const ATTACK_BASIC_COOLDOWN = 0.2  # Make attacks faster
```

All changes apply immediately (no code recompilation needed after Godot refresh).

---

## Adding a Skill/Upgrade (15 minutes)

### Step 1: Add to SkillTree
Edit `scripts/progression/SkillTree.gd` in `_initialize_skills()`:

```gdscript
"armor": {
	"level": 0,
	"max_level": 3,
	"effects": {
		"damage_reduction": [5, 10, 15]  # Reduce incoming damage by %
	}
}
```

### Step 2: Apply Effect
Edit `scripts/progression/UpgradeApplier.gd` in `apply_upgrades_to_player()`:

```gdscript
var armor_level = skill_tree.get_skill_level("armor")
if armor_level > 0:
	var damage_reduction = skill_tree.get_skill_effect("armor", "damage_reduction")
	player.damage_reduction_percent = damage_reduction / 100.0
```

### Step 3: Use Effect
In `PlayerEntity.gd` `take_damage()`:

```gdscript
func take_damage(damage: int) -> bool:
	# Apply damage reduction
	var reduced_damage = int(damage * (1.0 - damage_reduction_percent))
	# Rest of damage logic...
```

---

## Template: Adding a New Behavior Pattern (20 minutes)

```gdscript
# Create scripts/ai/MyBehavior.gd
extends AIBehavior
class_name MyBehavior

func _update_behavior(delta):
	match behavior_state:
		State.IDLE:
			# What happens when idle?
			if some_condition:
				change_state(State.CHASE)
		
		State.CHASE:
			# What happens during chase?
			if player_too_far:
				change_state(State.IDLE)
		
		State.ATTACK:
			# What happens during attack?
			state_timer -= delta
			if state_timer <= 0:
				change_state(State.CHASE)

func get_movement_direction() -> Vector2:
	match behavior_state:
		State.CHASE:
			return get_direction_to_player() * chase_speed
		State.ATTACK:
			return Vector2.ZERO  # Don't move while attacking
		_:
			return Vector2.ZERO
```

---

## Common Tasks Reference

| Task | File | Time |
|------|------|------|
| New attack | Create `scripts/combat/` | 20 min |
| New enemy | Create `scripts/entities/` + AI | 30 min |
| New level | Copy scene + register LevelManager | 15 min |
| Adjust balance | Edit `GameConfig.gd` | 5 min |
| New skill | Add to SkillTree + UpgradeApplier | 15 min |
| New AI behavior | Create `scripts/ai/` | 20 min |
| Bug fix | Find issue + update system | 10-60 min |

---

## Troubleshooting

### "Attack not executing"
- Check attack's `can_execute()` returns true
- Verify `player_ref` is set via `attack.set_player(player)`
- Ensure cooldown timer has elapsed

### "Enemy not moving"
- Check AI behavior's `get_movement_direction()` is returning non-zero Vector2
- Verify entity has `_process(delta)` that applies movement
- Check collision shape isn't disabled

### "Score not updating"
- Verify entity emits `died` signal
- Check GameManager is listening to signal
- Confirm `GameManager.add_score()` is being called

### "Level won't load"
- Verify scene path in `LevelManager.level_scenes` is correct
- Check scene file exists at that path
- Look for Godot console errors about missing resources

---

## Best Practices

1. **Always use GameConfig** for numeric values (not hardcoded numbers)
2. **Emit signals** instead of calling functions directly (loose coupling)
3. **Use class_name** for each new script (enables autocomplete)
4. **Test new content** in isolation first (add to empty scene)
5. **Comment confusing logic** (explain WHY, not WHAT)
6. **Follow naming conventions**:
   - Classes: `PascalCase` (PlayerEntity, BossGolem)
   - Functions: `snake_case` (take_damage, get_movement_direction)
   - Constants: `SCREAMING_SNAKE_CASE` (PLAYER_SPEED, MAX_HEALTH)

---

## Next Document
See [ARCHITECTURE.md](ARCHITECTURE.md) for system design details.
