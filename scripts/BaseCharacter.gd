extends CharacterBody2D
class_name BaseCharacter

## Base character class for Yie Ar Kung-Fu
## Implements arcade-perfect 1985 physics and state machine
## See CLAUDE.md for full specification

# State Machine
enum State {
	IDLE,
	WALK,
	JUMP_START,  # 1-frame wind-up before jump
	JUMP,        # Ascending (velocity.y < 0)
	FALL,        # Descending (velocity.y > 0)
	ATTACK,      # Any attack animation
	HIT,         # Taking damage / hitstun
	BLOCK,       # Defensive state (used by Club)
	DEAD         # KO animation
}

# Physics Constants (matching CLAUDE.md specs)
const GRAVITY: float = 980.0
const SPEED: float = 200.0
const JUMP_VELOCITY: float = -400.0

# Combat Constants
const HIT_STOP_FRAMES: int = 3
const FLASH_FRAMES: int = 1
const HITSTUN_FRAMES: int = 20

# Exported Variables (tweakable in Inspector)
@export var max_health: int = 100
@export var damage_flash_color: Color = Color(10.0, 10.0, 10.0, 1.0)  # Bright white flash (HDR)
@export var knockback_force: float = 150.0

# State
var current_state: State = State.IDLE
var health: int = 100

# Physics State
var jump_start_velocity: Vector2 = Vector2.ZERO  # Locked horizontal velocity during jump
var is_facing_right: bool = true

# Combat State
var hitstun_timer: int = 0
var hit_stop_timer: int = 0
var flash_timer: int = 0
var can_act: bool = true
var original_modulate: Color = Color.WHITE

# State Timers
var jump_start_frames: int = 0  # Counts frames in JUMP_START state

# Node References (must be set in scene or _ready)
var anim: AnimationPlayer
var sprite: Sprite2D
var hurt_area: Area2D
var damage_area: Area2D

# Hitbox Shapes (set per-frame in animations)
var hurt_rect: Rect2 = Rect2(-20, -40, 40, 80)
var damage_rect: Rect2 = Rect2(0, 0, 0, 0)  # No damage by default


func _ready() -> void:
	health = max_health

	# Get node references (children should be set up in scene)
	anim = get_node_or_null("AnimationPlayer")
	sprite = get_node_or_null("Sprite2D")
	hurt_area = get_node_or_null("HurtArea")
	damage_area = get_node_or_null("DamageArea")

	# Connect hit detection
	if damage_area:
		damage_area.area_entered.connect(_on_damage_area_entered)

	# Debug logging
	print("[%s] Ready | State: %s | Health: %d" % [name, State.keys()[current_state], health])


func _physics_process(delta: float) -> void:
	# Handle hit-stop (global freeze on successful hits)
	if hit_stop_timer > 0:
		hit_stop_timer -= 1
		return  # Freeze all logic during hit-stop

	# Handle flash effect
	if flash_timer > 0:
		# Keep the flash color applied
		if sprite:
			sprite.modulate = damage_flash_color
		flash_timer -= 1
		# Restore original color when flash ends
		if flash_timer == 0 and sprite:
			sprite.modulate = original_modulate

	# Handle hitstun
	if hitstun_timer > 0:
		hitstun_timer -= 1
		can_act = false
		if hitstun_timer == 0:
			can_act = true
			if current_state == State.HIT:
				transition_to(State.IDLE)

	# State machine update
	match current_state:
		State.IDLE:
			_state_idle(delta)
		State.WALK:
			_state_walk(delta)
		State.JUMP_START:
			_state_jump_start(delta)
		State.JUMP:
			_state_jump(delta)
		State.FALL:
			_state_fall(delta)
		State.ATTACK:
			_state_attack(delta)
		State.HIT:
			_state_hit(delta)
		State.BLOCK:
			_state_block(delta)
		State.DEAD:
			_state_dead(delta)

	# Apply physics
	move_and_slide()

	# Update sprite facing
	if sprite and velocity.x != 0 and can_act:
		if velocity.x > 0:
			sprite.flip_h = false
			is_facing_right = true
		elif velocity.x < 0:
			sprite.flip_h = true
			is_facing_right = false


# ============================================================================
# STATE IMPLEMENTATIONS
# ============================================================================

func _state_idle(delta: float) -> void:
	velocity.x = 0

	# Apply gravity if not on floor (can happen after landing)
	if not is_on_floor():
		velocity.y += GRAVITY * delta
		transition_to(State.FALL)


func _state_walk(delta: float) -> void:
	# Walk state is handled by child classes (Player/AI)
	# This is just the physics
	if not is_on_floor():
		velocity.y += GRAVITY * delta
		transition_to(State.FALL)


func _state_jump_start(delta: float) -> void:
	# 1-frame wind-up before jump
	# Lock in the horizontal velocity for the entire jump
	jump_start_velocity = velocity
	velocity.y = 0  # Don't apply gravity yet

	# Wait 1 frame before transitioning to JUMP
	if jump_start_frames > 0:
		jump_start_frames -= 1
		if jump_start_frames == 0:
			transition_to(State.JUMP)


func _state_jump(delta: float) -> void:
	# CRITICAL: Zero air control - velocity.x is locked!
	velocity.x = jump_start_velocity.x

	# Apply gravity
	velocity.y += GRAVITY * delta

	# Transition to FALL when descending
	if velocity.y > 0:
		transition_to(State.FALL)


func _state_fall(delta: float) -> void:
	# CRITICAL: Zero air control - velocity.x is still locked!
	velocity.x = jump_start_velocity.x

	# Apply gravity
	velocity.y += GRAVITY * delta

	# Land
	if is_on_floor():
		transition_to(State.IDLE)


func _state_attack(delta: float) -> void:
	# Attack state is animation-driven
	# Movement is locked during attacks
	velocity.x = 0

	# Apply gravity if airborne (aerial attacks)
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Transition handled by animation finished signal


func _state_hit(delta: float) -> void:
	# Taking damage - apply knockback
	# Knockback velocity is set by take_damage()

	# Apply gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Friction on ground
	if is_on_floor():
		velocity.x = lerp(velocity.x, 0.0, 0.1)


func _state_block(delta: float) -> void:
	# Block state (used by Club boss)
	velocity.x = 0

	if not is_on_floor():
		velocity.y += GRAVITY * delta


func _state_dead(delta: float) -> void:
	# Death animation - no control
	velocity.x = 0

	if not is_on_floor():
		velocity.y += GRAVITY * delta


# ============================================================================
# STATE TRANSITIONS
# ============================================================================

func transition_to(new_state: State) -> void:
	if current_state == new_state:
		return

	var old_state := current_state
	current_state = new_state

	# Debug logging
	print("[%s] State: %s → %s" % [name, State.keys()[old_state], State.keys()[new_state]])

	# State entry logic
	match new_state:
		State.IDLE:
			velocity.x = 0
			if anim and anim.has_animation("idle"):
				anim.play("idle")

		State.WALK:
			if anim and anim.has_animation("walk"):
				anim.play("walk")

		State.JUMP_START:
			# Set 1-frame delay before transitioning to JUMP
			jump_start_frames = 1

		State.JUMP:
			velocity.y = JUMP_VELOCITY
			if anim and anim.has_animation("jump"):
				anim.play("jump")

		State.FALL:
			if anim and anim.has_animation("fall"):
				anim.play("fall")

		State.HIT:
			can_act = false
			hitstun_timer = HITSTUN_FRAMES
			if anim and anim.has_animation("hit"):
				anim.play("hit")

		State.DEAD:
			can_act = false
			velocity = Vector2.ZERO
			if anim and anim.has_animation("death"):
				anim.play("death")


# ============================================================================
# COMBAT SYSTEM
# ============================================================================

func take_damage(amount: int, attacker_position: Vector2) -> void:
	if current_state == State.DEAD:
		return

	# Reduce health
	health -= amount
	print("[%s] Took %d damage | Health: %d/%d" % [name, amount, health, max_health])

	# Apply knockback
	var knockback_dir := sign(global_position.x - attacker_position.x)
	if knockback_dir == 0:
		knockback_dir = -1 if is_facing_right else 1
	velocity.x = knockback_dir * knockback_force
	velocity.y = -100  # Slight upward pop

	# Visual feedback - save original color before flashing
	if sprite and flash_timer == 0:
		original_modulate = sprite.modulate
	flash_timer = FLASH_FRAMES

	# Screen shake would go here (handled by camera in main scene)
	# Play sound would go here

	# State transition
	if health <= 0:
		transition_to(State.DEAD)
	else:
		transition_to(State.HIT)


func apply_hit_stop() -> void:
	# Trigger 3-frame freeze on successful hit
	hit_stop_timer = HIT_STOP_FRAMES

	# This would also freeze the opponent, but that requires
	# access to the game manager. For now, just freeze self.


func _on_damage_area_entered(area: Area2D) -> void:
	# This character's attack hit something
	if area.owner == self:
		return  # Don't hit self

	# Check if hit an enemy's hurt area
	if area.name == "HurtArea" and area.owner is BaseCharacter:
		var target := area.owner as BaseCharacter

		# Deal damage (amount would be set per-attack)
		var damage_amount := 10  # Placeholder
		target.take_damage(damage_amount, global_position)

		# Apply hit-stop to both characters
		apply_hit_stop()
		target.apply_hit_stop()

		# Visual/audio feedback
		print("[%s] HIT %s for %d damage!" % [name, target.name, damage_amount])


# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

func can_jump() -> bool:
	return is_on_floor() and can_act and current_state in [State.IDLE, State.WALK]


func can_attack() -> bool:
	return can_act and current_state in [State.IDLE, State.WALK, State.JUMP, State.FALL]


func start_jump() -> void:
	if can_jump():
		transition_to(State.JUMP_START)


func perform_attack(attack_name: String) -> void:
	if can_attack():
		transition_to(State.ATTACK)
		if anim and anim.has_animation(attack_name):
			anim.play(attack_name)
		else:
			print("[%s] WARNING: Animation '%s' not found" % [name, attack_name])
