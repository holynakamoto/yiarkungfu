# Yie Ar Kung-Fu - Agentic Rebirth

[![Godot CI](https://github.com/holynakamoto/yiarkungfu/actions/workflows/godot-ci.yml/badge.svg)](https://github.com/holynakamoto/yiarkungfu/actions/workflows/godot-ci.yml)

**Status:** Phase 1 Complete ✓

## Project Overview
A faithful recreation of the 1985 arcade classic with modern tooling but authentic physics and feel.

## Phase 1 Implementation (COMPLETED)

### What's Built
✓ Complete project structure
✓ BaseCharacter state machine with arcade-perfect physics
✓ Player with 16-move matrix input system
✓ 1-frame input buffer for frame-perfect attacks
✓ Zero air control (fixed jump trajectory)
✓ Box-on-box hitbox system
✓ Hit-stop system (3-frame freeze on hit)
✓ Main game scene with dojo and player spawn

### Testing Instructions

1. **Open in Godot 4.3+**
   ```bash
   godot4 --path /home/user/yiarkungfu
   ```

2. **Expected Behavior**
   - **Movement:** WASD or Arrow keys to walk left/right
   - **Jump:** Space or W key - should create fixed arc (NO air control)
   - **Attacks:** J (punch) / K (kick) with directional inputs
   - **State Transitions:** Watch console for state changes (IDLE → WALK → JUMP → FALL → IDLE)

3. **Critical Tests**

   **Test 1: Zero Air Control**
   - Jump forward (hold right + space)
   - Try pressing left during jump
   - Player should NOT change direction mid-air ✓

   **Test 2: 16-Move Matrix**
   - Press J (neutral punch) → should log "neutral_punch"
   - Hold forward + J → should log "forward_punch"
   - Hold down + K → should log "down_kick"
   - Jump + J → should log "air_neutral_punch"

   **Test 3: Input Buffer**
   - Tap forward, then quickly press J
   - Should execute "forward_punch" even if you release direction before J
   - Buffer window: 1 frame (16ms at 60fps)

   **Test 4: State Machine**
   - Watch console output for state transitions
   - States should flow: IDLE → WALK → JUMP_START → JUMP → FALL → IDLE
   - No invalid transitions should occur

4. **Known Limitations (By Design)**
   - No animations yet (sprites are colored rectangles)
   - No sounds yet
   - No enemies yet
   - Hitboxes defined but no collision response (needs opponent)

### Project Structure
```text
YieArKungFu_Rebirth/
├── CLAUDE.md               ← Master PRD (always reference this!)
├── README.md               ← This file
├── project.godot           ← Godot project config
├── scenes/
│   ├── main.tscn          ← Main game scene
│   └── characters/
│       ├── BaseCharacter.tscn
│       └── Player.tscn
├── scripts/
│   ├── BaseCharacter.gd   ← State machine + physics
│   └── Player.gd          ← 16-move matrix + input
└── assets/
    ├── sprites/           ← (Ready for pixel art)
    └── audio/             ← (Ready for SFX)
```

### CI/CD Pipeline

The project includes automated GitHub Actions workflows:

**Automated Checks (Every Push/PR):**
- ✓ Script validation (checks for parse errors in all .gd files)
- ✓ Project loading verification (smoke test)
- ✓ Web build export (validates export presets)

**Build Artifacts:**
- Web builds are automatically exported and available for download
- Future: Desktop builds (Linux, Windows, macOS)
- Future: Automated testing with gdUnit4

**Workflow Status:**
Check the badge at the top of this README for current build status.

### Key Implementation Details

**BaseCharacter.gd (scripts/BaseCharacter.gd:1)**
- State machine: 9 states (IDLE, WALK, JUMP_START, JUMP, FALL, ATTACK, HIT, BLOCK, DEAD)
- Physics: GRAVITY=980, SPEED=200, JUMP_VELOCITY=-400
- Zero air control: velocity.x locked during JUMP/FALL states (scripts/BaseCharacter.gd:147)
- Hit-stop: 3-frame freeze on successful hit (scripts/BaseCharacter.gd:231)

**Player.gd (scripts/Player.gd:1)**
- 16-move matrix: All direction+button combinations mapped (scripts/Player.gd:18)
- 1-frame input buffer: Stores directional input for precise execution (scripts/Player.gd:42)
- Move execution: Direction-aware attack selection (scripts/Player.gd:112)

### Console Debug Output
When running, you should see logs like:
```text
[Player] Ready | State: IDLE | Health: 100
[Player] 16-Move Matrix loaded with 16 moves
[Player] State: IDLE → WALK
[Player] Input Buffer: dir=(1, 0), timer=1, facing_right=true
[Player] Execute: forward_punch -> punch_forward
[Player] State: WALK → JUMP_START
[Player] State: JUMP_START → JUMP
[Player] State: JUMP → FALL
[Player] State: FALL → IDLE
```

### Next Steps (Phase 2)

1. **Add Animations**
   - Create sprite sheets for Oolong (player)
   - Animate all 16 moves + idle/walk/jump
   - Hook up AnimationPlayer in scenes

2. **First Boss: Star**
   - Implement AI_Coordinator.gd
   - Create Star character with zoning behavior
   - Add shuriken projectile system

3. **Polish Pass**
   - Add sound effects (thud, swish, clink)
   - Implement screenshake on hits
   - Add visual effects (hit flash, particles)

### Development Notes

- **Always reference CLAUDE.md** before implementing features
- **No air control** - this is intentional! 1985 arcade accuracy
- **Box-on-box only** - no capsule collisions
- **1-frame buffer** - enables frame-perfect inputs like real arcade
- **60 FPS locked** - critical for hit-stop timing

### Troubleshooting

**Player falls through floor:**
- Check that Floor has StaticBody2D with CollisionShape2D
- Verify Player has CollisionShape2D (not just Areas)

**Inputs not working:**
- Check project.godot has input mappings (move_left, move_right, jump, punch, kick)
- Verify Player.gd is attached to Player node

**No state transitions:**
- Check console output for errors
- Verify BaseCharacter.gd script is attached
- Check that AnimationPlayer node exists (even without animations)

**Attacks not executing:**
- Press J or K while watching console
- Check if input buffer logs appear
- Verify move_matrix keys match the generated keys

### Credits
- **Original Game:** Konami (1985)
- **Rebirth Project:** Agentic development with Claude Code
- **PRD:** See CLAUDE.md for complete specification

---

**Ready to test?** Open in Godot 4.3+ and press F5 to run!
