# PRD: Yie Ar Kung-Fu - Agentic Rebirth (2026)

## CRITICAL REFERENCE DOCUMENT
**This file contains the complete game specification. Always reference this before implementing features.**

---

## 1. Core Engine & Global Mechanics

**Objective:** Replicate the high-friction, frame-perfect arcade feel of 1985.

### The 16-Move Matrix
Movement is not "modern." Attacks are determined by `Direction + Button` at the moment of press.

**Complete Move Matrix:**
```
PUNCH BUTTON:
- Neutral + Punch = High Punch (standing jab)
- Forward + Punch = Forward Punch (reach attack)
- Back + Punch = Back Punch (reverse strike)
- Down + Punch = Low Punch (crouching jab)
- Up + Punch = Uppercut (anti-air)
- Jump + Neutral Punch = Air Punch (neutral jump attack)
- Jump + Forward Punch = Flying Punch (aerial approach)
- Jump + Back Punch = Retreat Punch (defensive aerial)

KICK BUTTON:
- Neutral + Kick = High Kick (standing kick)
- Forward + Kick = Forward Kick (advancing kick)
- Back + Kick = Back Kick (retreat kick)
- Down + Kick = Low Kick (sweep)
- Up + Kick = Rising Kick (launcher)
- Jump + Neutral Kick = Air Kick (neutral jump attack)
- Jump + Forward Kick = Flying Kick (aerial approach)
- Jump + Back Kick = Retreat Kick (defensive aerial)
```

**AI Implementation Rule:** Use a **1-frame buffer** to check directional input when a punch/kick is registered.

### Physics System
- **Zero Air Control:** Once a jump starts, the trajectory is FIXED. No mid-air direction changes.
- **Gravity:** Constant 980.0 units/sec² (Godot standard)
- **Jump Velocity:** -400.0 (fixed arc)
- **Ground Speed:** 200.0 units/sec

### Hitbox Standards
- **Box-on-Box ONLY:** No capsule collisions. Each animation frame must have manually defined rectangles.
- **DamageArea:** The attacking hitbox (what deals damage)
- **HurtArea:** The vulnerable hitbox (what receives damage)
- **Per-Frame Definition:** Each animation frame can have different hitbox sizes/positions

### Hit-Stop (The "Crunch")
On every successful hit:
1. Freeze game for **3 frames** (0.05 seconds at 60fps)
2. Flash hit character **white for 1 frame**
3. Apply **screenshake** scaled to damage
4. Play **distinct sound** (Thud/Swish/Clink)

---

## 2. Character Roster (The Full 13)

Use a `BaseCharacter` inheritance model for all characters.

### Gauntlet 1: Hot Fighting History

#### Buchu
- **Weapon:** Unarmed
- **Archetype:** Big Body Grappler
- **Special Move:** Leaping Headbutt
- **AI Logic:**
  - Aggressive close-range pressure
  - Uses headbutt when player at mid-range
  - Vulnerable to low attacks during jump startup
  - If hit low during jump, immediate knockdown

#### Star
- **Weapon:** Shuriken (Throwing Stars)
- **Archetype:** Zoner / Projectile
- **Special Move:** Triple-Height Star Throw
- **AI Logic:**
  - **Distance > 200px:** Throw shuriken at randomized height (high/mid/low)
  - **Distance < 200px:** Back-dash to create space OR use kick if cornered
  - **Shuriken Speed:** 300 units/sec (dodgeable but fast)
  - **Cooldown:** 60 frames (1 second) between throws
  - **Zoning Pattern:** Prefers edge positions (left 20% or right 20% of screen)

#### Nuncha
- **Weapon:** Nunchaku
- **Archetype:** Mid-Range Rush
- **Special Move:** Nunchuck Whirl (anti-air)
- **AI Logic:**
  - Rapid strikes at mid-range (150-250px)
  - Uses whirl as anti-air when player jumps
  - Pressures with alternating high/low chains

#### Pole
- **Weapon:** Bo Staff
- **Archetype:** Long-Range Poker
- **Special Move:** Pole Vault
- **AI Logic:**
  - Uses staff pokes to maintain distance (250-350px optimal)
  - Pole vault: Jumps OVER player to swap sides
  - Retreats if player gets inside staff range

#### Feedle
- **Weapon:** Army (Clones)
- **Archetype:** Crowd Control
- **Special Move:** Clone Spawn
- **AI Logic:**
  - Main Feedle stays center-screen
  - Clones spawn from left/right edges every 3 seconds
  - **1-hit KO:** All Feedles die in one hit
  - **Win Condition:** Defeat 10 clones + main Feedle

### Gauntlet 2: Masterhand History

#### Chain
- **Weapon:** Claw-Chain
- **Archetype:** High-Risk High-Reward
- **Special Move:** Chain Whip
- **AI Logic:**
  - Only the chain HEAD is a hitbox
  - High recovery time (30 frames)
  - Uses chain at max range (400px)
  - Vulnerable during recovery

#### Club
- **Weapon:** Club + Shield
- **Archetype:** Defensive Tank
- **Special Move:** Shield Block (invincible during block)
- **AI Logic:**
  - Default state: **BLOCK**
  - Only attacks when player is in recovery frames
  - Shield blocks all frontal attacks
  - Vulnerable to throws/grabs (if implemented)

#### Fan
- **Weapon:** Steel Fans
- **Archetype:** Projectile + Speed
- **Special Move:** Sine-Wave Fan Throw
- **AI Logic:**
  - **Projectile Pattern:** Fans float in sine wave (amplitude: 50px, frequency: 2Hz)
  - **Kick Speed:** Fastest in game (4-frame startup)
  - **Distance < 150px:** Uses kicks
  - **Distance > 150px:** Throws fans
  - **Fan Speed:** 250 units/sec (slower than Star's shuriken but curved)

#### Sword
- **Weapon:** Dao (Chinese Sword)
- **Archetype:** Teleport Rushdown
- **Special Move:** Shadow Dash
- **AI Logic:**
  - Dash-heavy movement (300 units/sec dash speed)
  - **Teleport:** Moves off-screen (top edge), reappears behind player
  - Uses teleport when player turtles for > 5 seconds
  - Fast sword slashes (6-frame startup)

#### Tonfun
- **Weapon:** Dual Tonfa
- **Archetype:** Frame-Trap Specialist
- **Special Move:** Tonfa Flurry
- **AI Logic:**
  - **Highest attack speed** (3-frame startup)
  - Punishes button mashing with frame-perfect counters
  - Uses blockstrings: High → Low → High chains
  - Adapts to player patterns (if player mashes, uses counters)

#### Blues (Mirror Match)
- **Weapon:** Unarmed (same as player)
- **Archetype:** AI Mirror
- **Special Move:** Player's Most-Used Move
- **AI Logic:**
  - **Moves 120% faster** than player
  - **Learning System:** Tracks player's top 3 most-used moves
  - Uses player's favorite move against them
  - Perfect input reading (2-frame reaction time)

### Console/Regional Exclusives

#### Tao
- **Version:** NES/MSX
- **Weapon:** Fire Breath
- **Archetype:** Stationary Turret
- **AI Logic:**
  - Stays in center of screen
  - Breathes fire in horizontal line (full screen width)
  - Fire lasts 15 frames
  - 2-second cooldown between breaths

#### Bishoo
- **Version:** Game Boy (Hidden Character)
- **Weapon:** Daggers
- **Archetype:** Multi-Projectile
- **AI Logic:**
  - Throws daggers in spread of 3 (15° angle separation)
  - Uses diagonal jumps to create space
  - Requires unlock code or perfect clear

---

## 3. Polish & "Game Juice"

**This section separates professional games from prototypes.**

### Visual Feedback
- **Sprite Flash:** White flash for 1 frame on damage
- **Screenshake:** Scales with damage (light hit: 2px, heavy: 8px)
- **Slow-Mo Finish:** Final hit triggers 0.3x time scale for 30 frames
- **Death Animations:**
  - Male characters: Fall on back, legs flailing
  - Female characters: Fall on side, fainting pose

### Audio Archetypes
- **Thud:** Heavy hits (punches, kicks landing)
- **Swish:** Missed attacks (whiff sounds)
- **Clink:** Blocked attacks (Club shield, parries)
- **Ko:** Distinct defeat sound per character type

### Background Effects
- **Dojo Color Cycle:** Background shifts hue every gauntlet clear
- **Crowd Reactions:** (Optional) Silhouette audience cheers on big hits

---

## 4. State Machine Design

### BaseCharacter States (Enum)
```gdscript
enum State {
    IDLE,
    WALK,
    JUMP_START,  # 1-frame wind-up
    JUMP,        # Ascending
    FALL,        # Descending
    ATTACK,      # Any attack animation
    HIT,         # Taking damage / hitstun
    BLOCK,       # Defensive state (Club)
    DEAD         # KO animation
}
```

### State Transitions
```
IDLE → WALK: Input direction != 0
IDLE → JUMP_START: Jump input + on_floor()
JUMP_START → JUMP: After 1 frame
JUMP → FALL: velocity.y > 0
FALL → IDLE: on_floor()
Any → ATTACK: Attack input + can_act()
ATTACK → IDLE: Animation finished
Any → HIT: take_damage() called
HIT → IDLE: Hitstun timer expires
Any → DEAD: health <= 0
```

---

## 5. Implementation Phases

### Phase 1: Foundation (CURRENT)
**Goal:** Playable skeleton with state machine

**Deliverables:**
- [ ] CLAUDE.md created (this file)
- [ ] Godot 4.3 project structure
- [ ] BaseCharacter.gd with FSM
- [ ] Player.gd with basic input
- [ ] main.tscn with dojo + player spawn
- [ ] Zero air control physics working
- [ ] Box-on-box hitboxes defined

### Phase 2: The 16-Move Matrix
**Goal:** Complete player attack system

**Deliverables:**
- [ ] Direction + Button input buffer (1-frame window)
- [ ] All 16 moves mapped in dictionary
- [ ] Placeholder animations for each move
- [ ] Attack canceling rules (can't cancel recovery)
- [ ] Hit-stop on successful hit (3 frames)

### Phase 3: First Boss (Star)
**Goal:** Prove AI + projectile systems

**Deliverables:**
- [ ] AI_Coordinator.gd behavior tree base
- [ ] Star.gd with zoning AI
- [ ] Shuriken projectile (Area2D with box collision)
- [ ] 3-height randomization logic
- [ ] Distance-based decision making
- [ ] Win/loss conditions

### Phase 4: Roster Expansion
**Goal:** All 13 characters playable

**Iterate through:**
1. Buchu (headbutt logic)
2. Nuncha (chain attacks)
3. Pole (pole vault)
4. Feedle (clone spawning)
5. Chain (whip physics)
6. Club (block state)
7. Fan (sine-wave projectile)
8. Sword (teleport)
9. Tonfun (frame-traps)
10. Blues (mirror match)
11. Tao (fire breath)
12. Bishoo (spread daggers)

### Phase 5: Polish Pass
**Goal:** Arcade-perfect feel

**Deliverables:**
- [ ] All sound effects integrated
- [ ] Screenshake on all hits
- [ ] Slow-mo finishes
- [ ] Death animations per character type
- [ ] Dojo background color cycling
- [ ] UI/HUD (health bars, round timer)

---

## 6. Technical Specifications

### Godot Version
- **Godot 4.3** (or latest 4.x stable)

### Project Structure
```
YieArKungFu_Rebirth/
├── CLAUDE.md (this file)
├── project.godot
├── scenes/
│   ├── main.tscn
│   ├── characters/
│   │   ├── BaseCharacter.tscn
│   │   ├── Player.tscn
│   │   ├── AI_Star.tscn
│   │   ├── AI_Buchu.tscn
│   │   └── [... all 13 characters]
│   └── ui/
│       ├── HealthBar.tscn
│       └── HUD.tscn
├── scripts/
│   ├── BaseCharacter.gd
│   ├── Player.gd
│   ├── AI_Coordinator.gd
│   └── [character scripts]
├── assets/
│   ├── sprites/
│   │   ├── player/
│   │   ├── star/
│   │   └── [character folders]
│   ├── audio/
│   │   ├── sfx/
│   │   └── music/
│   └── backgrounds/
└── addons/ (if needed for behavior trees)
```

### Code Standards
- **GDScript Only:** No C# for simplicity
- **Typed Variables:** Use `var name: Type` for clarity
- **Constants:** ALL_CAPS for magic numbers
- **Export Vars:** Use `@export` for inspector tweaking
- **Comments:** Only where logic isn't self-evident

### Performance Targets
- **60 FPS:** Rock-solid frame rate
- **Input Latency:** < 2 frames (33ms)
- **Load Time:** < 1 second between rounds

---

## 7. AI Behavior Trees (Detailed)

### Star (Zoner) Behavior Tree
```
ROOT (Selector)
├── Sequence: "Throw Shuriken"
│   ├── Condition: distance_to_player > 200
│   ├── Condition: cooldown_timer <= 0
│   ├── Action: choose_random_height() # high/mid/low
│   ├── Action: throw_shuriken(height)
│   └── Action: set_cooldown(60 frames)
├── Sequence: "Back Dash"
│   ├── Condition: distance_to_player < 150
│   ├── Condition: not_cornered()
│   └── Action: dash_backward()
├── Sequence: "Emergency Kick"
│   ├── Condition: distance_to_player < 100
│   └── Action: perform_kick()
└── Action: "Maintain Distance"
    └── move_toward_zone_position() # left/right 20% screen
```

### Fan (Sine-Wave Projectile) Behavior Tree
```
ROOT (Selector)
├── Sequence: "Throw Fan"
│   ├── Condition: distance_to_player > 150
│   ├── Condition: cooldown_timer <= 0
│   ├── Action: throw_fan_projectile()
│   │   └── Projectile Physics:
│   │       - base_velocity = Vector2(250, 0) toward player
│   │       - sine_offset.y = sin(time * 2π * 2Hz) * 50px
│   │       - update position each frame
│   └── Action: set_cooldown(45 frames)
├── Sequence: "Fast Kick"
│   ├── Condition: distance_to_player < 150
│   └── Action: perform_fast_kick() # 4-frame startup
└── Action: "Circle Strafe"
    └── move_perpendicular_to_player()
```

### Buchu (Headbutt) Behavior Tree
```
ROOT (Selector)
├── Sequence: "Leaping Headbutt"
│   ├── Condition: distance_to_player in [150, 300]
│   ├── Condition: on_floor()
│   └── Action: jump_toward_player()
│       └── Vulnerable State: if hit_low() during jump → instant_knockdown()
├── Sequence: "Close Combat"
│   ├── Condition: distance_to_player < 150
│   └── Action: random_punch_or_throw()
└── Action: "Advance"
    └── walk_toward_player()
```

---

## 8. Critical Rules (Always Enforce)

1. **No Capsule Collisions:** Only RectangleShape2D for hitboxes
2. **No Air Control:** `velocity.x` is locked during JUMP/FALL states
3. **1-Frame Buffer:** Direction input stored for 1 frame before attack check
4. **3-Frame Hit-Stop:** Every successful hit freezes game briefly
5. **Manual Hitbox Frames:** Never use automatic collision shapes
6. **State-Driven Logic:** All behavior in `match state:` blocks
7. **60 FPS Target:** Use `delta` properly, avoid frame-dependent code
8. **No Modern Conveniences:** No combo meters, no tutorials, pure arcade

---

## 9. Testing Checklist (Per Phase)

### Phase 1 Tests
- [ ] Player can walk left/right
- [ ] Player can jump with fixed arc
- [ ] No air control (press left/right during jump = no effect)
- [ ] Player lands and returns to IDLE
- [ ] State machine logs state changes correctly

### Phase 2 Tests
- [ ] All 16 moves execute correctly
- [ ] Direction + Button buffered within 1 frame
- [ ] Attack animations don't allow movement
- [ ] Hit-stop triggers on successful hit
- [ ] Hitboxes visualized (debug draw)

### Phase 3 Tests
- [ ] Star AI throws shurikens at 3 heights
- [ ] Star backs away when player approaches
- [ ] Projectiles despawn offscreen
- [ ] Hit detection works (player vs shuriken, player vs Star)
- [ ] Win condition triggers when Star's health = 0

---

## 10. Agentic Development Tips

### For Claude Code / Cursor
- **Always reference this file** before writing code
- **Ask before deviating** from the spec (no "improvements")
- **Test after each feature:** Don't batch implementation
- **Use debug visualization:** Draw hitboxes with `draw_rect()`
- **Log state changes:** Use `print()` to verify FSM flow

### Prompt Templates
```
"Implement [Feature] according to CLAUDE.md section [X]"
"Debug why [Behavior] isn't matching CLAUDE.md spec"
"Add the next character from CLAUDE.md roster: [Name]"
```

### When Stuck
1. Re-read relevant CLAUDE.md section
2. Check Godot docs for 4.x syntax changes
3. Test in isolation (single-character scene)
4. Ask for behavior tree clarification

---

## VERSION HISTORY
- **v1.0** (2026-01-18): Initial PRD with full roster, mechanics, and behavior trees
- **v1.1** (2026-01-18): Added Phase 1 implementation details

---

**END OF MASTER CONTEXT DOCUMENT**

*Remember: This is 1985 arcade perfection, not 2026 handholding. Every frame matters. Every hitbox is deliberate. Make Yie Ar Kung-Fu feel like it was coded in 6502 assembly, but with the power of Godot 4.*
