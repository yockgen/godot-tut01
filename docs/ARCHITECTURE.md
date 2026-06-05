# Godot Game Architecture Documentation

## Overview

This project has been refactored with a layered, extensible architecture to support adding multiple enemy types, attacks, levels, and progression systems. The codebase is organized into logical systems, each with clear responsibilities.

---

## Architecture Layers

### **Layer 1: Entities (Base Classes)**
**Location:** `scripts/entities/`

The foundation - all game characters inherit from these base classes for unified behavior.

- **Entity.gd** - Base class for all combatants
  - Manages health, state (NORMAL, FREEZE, BULLET_TIME, DEAD)
  - Handles damage, healing, death
  - Emits signals: `health_changed`, `died`, `state_changed`, `hit_received`
  - **Use when:** Creating player-like or enemy-like objects

- **Enemy.gd** - Base for all enemy types
  - Extends Entity with enemy-specific behavior
  - Manages scoring on defeat
  - Placeholder for AI behavior
  - **Use when:** Creating a new mob or boss type

- **Boss.gd** - Boss entity with phases
  - Extends Enemy
  - Supports phase transitions
  - Health bar integration (signals)
  - **Use when:** Creating a boss fight

- **PlayerEntity.gd** - Player character
  - Extends Entity
  - Manages dash mechanics, invincibility, bullet-time
  - State tracking for freezes and slow-motion
  - **Use when:** Adding player-specific abilities

### **Layer 2: Combat Systems**
**Location:** `scripts/combat/` and `scripts/animation/`

Attack execution and animation management.

- **Attack.gd** - Base class for all attacks
  - Cooldown management
  - Execution control
  - Signals: `executed`, `started`, `finished`, `cooldown_changed`
  - **Extend this to add:** New attack types
  
- **BasicAttack.gd**, **Finisher01.gd**, **Finisher02.gd** - Specific attacks
  - Each implements `_perform_attack()` with unique behavior
  - Handles animation and hitbox detection
  - **Add new attacks:** Create new `class_name` extending `Attack`

- **AnimationController.gd** - Animation state machine
  - Replaces hardcoded `is_animation_locked()` checks
  - Manages locked animations (input blocking during attacks)
  - **Use when:** Synchronizing animations with game state

### **Layer 3: AI & Behavior**
**Location:** `scripts/ai/`

Defines how enemies move and act.

- **AIBehavior.gd** - Base behavior state machine
  - States: IDLE, PATROL, CHASE, ATTACK, RETREAT, DEAD
  - Helper methods: distance checking, direction calculation
  - **Extend this to add:** New behavior types

- **PatrolBehavior.gd** - Patrol + Chase hybrid
  - Wanders in an area, chases on player detection
  - **Use for:** Common minion behavior

- **ChaseBehavior.gd** - Always-chase aggressive
  - Pursues player relentlessly
  - **Use for:** Aggressive enemy types

- **AttackBehavior.gd** - Stationary attacker
  - Waits for player in range, then attacks
  - **Use for:** Turret-like enemies

### **Layer 4: Managers (Singletons)**
**Location:** `scripts/managers/`, `scripts/config/`, `scripts/ui/`, `scripts/progression/`

Global systems accessible from anywhere.

- **GameManager.gd** (Autoload)
  - Score tracking
  - Global pause state
  - Entity defeat tracking
  - Audio management interface
  - Signals: `score_changed`, `pause_toggled`, `game_over`, `level_completed`, `entity_defeated`
  - **Access via:** `GameManager.add_score(100)`, `GameManager.set_pause(true)`

- **GameConfig.gd** (Autoload)
  - All balance constants in one place
  - Player speed, damage, cooldowns
  - Mob spawn rates, health, scoring values
  - **Access via:** `GameConfig.PLAYER_SPEED`, `GameConfig.MOB_HEALTH`
  - **Update before shipping:** Adjust all export-like values here

- **LevelManager.gd** (Autoload)
  - Level progression and transitions
  - Difficulty scaling
  - Progress tracking per level
  - Signals: `level_loaded`, `level_completed`, `level_failed`, `progression_updated`
  - **Use for:** Loading levels, tracking completion, difficulty adjustments

- **PauseManager.gd** (Autoload)
  - Centralized pause control
  - Responds to ESC key input
  - Emits pause signals globally
  - **Use for:** Handling pause/resume from any system

- **SkillTree.gd** (Autoload)
  - Player upgrades and progression
  - Skill levels and effects
  - Signals: `skill_unlocked`, `skill_upgraded`, `skill_points_changed`
  - **Use for:** Tracking player progression

- **UpgradeApplier.gd** (Autoload)
  - Applies skill tree bonuses to entities
  - Difficulty scaling for enemies
  - **Use for:** Translating upgrades into gameplay effects

---

## Signal Flow (Communication Pattern)

The game uses **signals** for decoupled communication:

```
Event happens in Entity
    ↓
Entity emits signal (e.g., "died")
    ↓
Managers listen and react (GameManager adds score)
    ↓
Managers emit their own signals (GameManager emits "score_changed")
    ↓
UI listens to manager signals and updates
```

**Example:** Enemy defeated
```
Enemy.take_damage(10)
  → Enemy health reaches 0
  → Enemy emits "died"
  → GameManager hears "died" signal
  → GameManager.add_score(enemy.score_on_defeat)
  → GameManager emits "score_changed"
  → UI listens to "score_changed" and updates display
```

---

## How to Add Content

### **Adding a New Attack Type**

1. Create `scripts/combat/MyNewAttack.gd`:
```gdscript
extends Attack
class_name MyNewAttack

func _ready():
    attack_name = "My New Attack"
    damage = 15
    cooldown = 0.7
    animation_name = "my_animation"

func _perform_attack(target_position: Vector2):
        # Implement attack logic here
    # Play animation, create hitbox, apply effects
    await get_tree().create_timer(animation_length).timeout
    finish_execution()
```

2. Reference in Player.gd (when player attacks system is integrated):
```gdscript
attacks = [BasicAttack.new(), Finisher01.new(), MyNewAttack.new()]
```

3. Test via `attacks[2].execute()` in player input handler.

### **Adding a New Enemy Type**

1. Create `scripts/entities/MyNewEnemy.gd`:
```gdscript
extends Enemy
class_name MyNewEnemy

func _initialize():
    max_health = 5  # Specific to this enemy
    score_on_defeat = 200
```

2. Create `scripts/ai/MyNewBehavior.gd` (if unique behavior needed):
```gdscript
extends AIBehavior
class_name MyNewBehavior

func _update_behavior(delta):
    # Custom behavior logic
```

3. Spawn in main.gd:
```gdscript
var enemy = MyNewEnemy.new()
enemy.set_ai_behavior(MyNewBehavior.new())
add_child(enemy)
```

### **Adding a Difficulty Setting**

1. Open `GameConfig.gd`
2. Add constant:
```gdscript
const DIFFICULTY_HEALTH_MULTIPLIER = 1.5
```
3. Use in enemy spawning:
```gdscript
var health = base_health * GameConfig.DIFFICULTY_HEALTH_MULTIPLIER
```

### **Adding a New Level**

1. Create new `.tscn` file (copy main.tscn as template)
2. Register in `LevelManager._initialize_levels()`:
```gdscript
level_scenes = {
    1: "res://main.tscn",
    2: "res://levels/level_2.tscn"  # Add this line
}
```
3. Load via: `LevelManager.load_level(2)`

### **Adding a New Skill/Upgrade**

1. Open `SkillTree.gd`
2. Add to `_initialize_skills()`:
```gdscript
"crit_chance": {
    "level": 0,
    "max_level": 3,
    "effects": {
        "crit_percent": [10, 20, 30]
    }
}
```
3. Apply in `UpgradeApplier.apply_upgrades_to_player()`:
```gdscript
var crit_level = skill_tree.get_skill_level("crit_chance")
if crit_level > 0:
    var crit_percent = skill_tree.get_skill_effect("crit_chance", "crit_percent")
    player.crit_chance = crit_percent / 100.0
```

---

## File Organization

```
scripts/
├── entities/           # Base classes and implementations
│   ├── Entity.gd       # Base for all entities
│   ├── Enemy.gd        # Base for enemies
│   ├── Boss.gd         # Boss-specific behavior
│   └── PlayerEntity.gd # Player implementation
├── combat/             # Attack system
│   ├── Attack.gd       # Attack base class
│   ├── BasicAttack.gd  # Simple melee
│   ├── Finisher01.gd   # Spin attack
│   └── Finisher02.gd   # Dash attack
├── ai/                 # Behavior patterns
│   ├── AIBehavior.gd   # Behavior base class
│   ├── PatrolBehavior.gd
│   ├── ChaseBehavior.gd
│   └── AttackBehavior.gd
├── animation/          # Animation control
│   └── AnimationController.gd
├── managers/           # Global systems (autoloaded)
│   ├── GameManager.gd  # Score, pause, state
│   └── LevelManager.gd # Levels and progression
├── config/             # Configuration
│   └── GameConfig.gd   # Balance constants
├── ui/                 # UI systems
│   └── PauseManager.gd # Pause handling
└── progression/        # Player progression
    ├── SkillTree.gd    # Skills and upgrades
    └── UpgradeApplier.gd # Apply upgrades to entities
```

---

## State Machines

### **Entity State Machine**
```
NORMAL ↔ FREEZE ↔ BULLET_TIME
  ↓
DEAD (final)
```

### **AI Behavior State Machine**
```
IDLE ↔ PATROL
  ↓
CHASE ↔ ATTACK
  ↓
RETREAT
  ↓
DEAD (final)
```

### **Animation States**
Controlled by AnimationController:
- Locked animations block input (swing, dance, etc.)
- Transitions managed by signal `animation_finished`
- Manual lock available via `animation_controller.lock_input(duration)`

---

## Testing Checklist

- [ ] Entity takes damage and dies correctly
- [ ] GameManager score updates on entity defeat
- [ ] New attack executes without errors
- [ ] New enemy spawns with correct AI behavior
- [ ] Level transitions work
- [ ] Pause/resume functions globally
- [ ] Skill upgrades apply to player
- [ ] Physics collisions work (no phasing)
- [ ] Audio plays on events (if implemented)
- [ ] Memory usage stable (no leaks)

---

## Debugging

### Print Entity Debug Info
```gdscript
print(entity.get_debug_info())
# Output: "HP: 5/10 | State: NORMAL | Speed: 400"
```

### Print GameManager State
```gdscript
print(GameManager.get_debug_info())
# Output: "Score: 1500 | Paused: false | Level: 1 | GameOver: false"
```

### Print AI Behavior State
```gdscript
print(enemy.ai_behavior.get_debug_info())
# Output: "Behavior: CHASE | Player Dist: 150.5 | Detection: 300"
```

---

## Performance Notes

- Entity pooling (recommended for later): Pre-create and reuse entity instances instead of instantiating
- Hitbox optimization: Use simple CircleShape2D/RectangleShape2D before complex collision shapes
- Animation: Keep frame counts reasonable (<20 frames for smooth 60fps)
- Signals: Minimal overhead; safe to use extensively for decoupling

---

## Next Steps (Future Phases)

1. **Integrate Player Attack System** - Wire Player.gd to use Attack registry
2. **Enemy Spawning Factory** - Create factory for instantiating enemies with behaviors
3. **UI Implementation** - Create score display, pause menu, level select
4. **Persistence** - Save/load player progression via SkillTree data
5. **Advanced Boss AI** - Implement multi-phase boss with complex attack patterns
6. **Combo System** - Add combo detection and execution
7. **Audio Manager** - Centralized sound effect playback

---

## Questions?

Each system's code is documented with comments. Start with the class definitions (Entity, Enemy, Attack, etc.) to understand the architecture flow.
