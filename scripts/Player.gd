extends BaseCharacter
class_name Player

## Player character implementation
## Implements the 16-Move Matrix with 1-frame input buffer
## See CLAUDE.md Section 1: "The 16-Move Matrix"

# Input Buffer (1-frame memory for directional input)
var buffered_direction: Vector2 = Vector2.ZERO
var direction_buffer_timer: int = 0
const BUFFER_FRAMES: int = 1

# Move Matrix - Maps direction + button to animation name
# Format: "direction_button" -> "animation_name"
var move_matrix: Dictionary = {
	# PUNCH MOVES (8 total)
	"neutral_punch": "punch_high",
	"forward_punch": "punch_forward",
	"back_punch": "punch_back",
	"down_punch": "punch_low",
	"up_punch": "punch_uppercut",
	"air_neutral_punch": "air_punch",
	"air_forward_punch": "flying_punch",
	"air_back_punch": "retreat_punch",

	# KICK MOVES (8 total)
	"neutral_kick": "kick_high",
	"forward_kick": "kick_forward",
	"back_kick": "kick_back",
	"down_kick": "kick_low",
	"up_kick": "kick_rising",
	"air_neutral_kick": "air_kick",
	"air_forward_kick": "flying_kick",
	"air_back_kick": "retreat_kick"
}


func _ready() -> void:
	super._ready()
	print("[Player] 16-Move Matrix loaded with %d moves" % move_matrix.size())


func _physics_process(delta: float) -> void:
	# Update input buffer BEFORE parent physics
	_update_input_buffer()

	# Handle player input (only if can act)
	if can_act:
		_handle_movement_input(delta)
		_handle_attack_input()

	# Call parent physics (state machine, gravity, etc.)
	super._physics_process(delta)


# ============================================================================
# INPUT BUFFER SYSTEM (1-frame memory)
# ============================================================================

func _update_input_buffer() -> void:
	# Get current directional input
	var current_direction := _get_directional_input()

	# If direction changed, update buffer and reset timer
	if current_direction != Vector2.ZERO:
		buffered_direction = current_direction
		direction_buffer_timer = BUFFER_FRAMES

	# Decay buffer timer
	if direction_buffer_timer > 0:
		direction_buffer_timer -= 1
	else:
		buffered_direction = Vector2.ZERO


func _get_directional_input() -> Vector2:
	# Get raw input (not normalized - we want discrete directions)
	var input_dir := Vector2.ZERO

	if Input.is_action_pressed("move_right"):
		input_dir.x = 1
	elif Input.is_action_pressed("move_left"):
		input_dir.x = -1

	if Input.is_action_pressed("jump"):  # Up input
		input_dir.y = -1

	# Check for down input (crouch/down attacks)
	# Note: In Godot, we don't have a default "move_down" action
	# We'll use S key or Down arrow for this
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		input_dir.y = 1

	return input_dir


# ============================================================================
# MOVEMENT INPUT
# ============================================================================

func _handle_movement_input(delta: float) -> void:
	# Only allow movement in specific states
	if current_state not in [State.IDLE, State.WALK]:
		return

	# Get horizontal input
	var input_x := 0.0
	if Input.is_action_pressed("move_right"):
		input_x = 1.0
	elif Input.is_action_pressed("move_left"):
		input_x = -1.0

	# Apply movement
	if input_x != 0:
		velocity.x = input_x * SPEED
		if current_state == State.IDLE:
			transition_to(State.WALK)
	else:
		velocity.x = 0
		if current_state == State.WALK:
			transition_to(State.IDLE)

	# Jump input (only from ground)
	if Input.is_action_just_pressed("jump") and can_jump():
		start_jump()


# ============================================================================
# ATTACK INPUT (THE 16-MOVE MATRIX)
# ============================================================================

func _handle_attack_input() -> void:
	if not can_attack():
		return

	# Check for punch input
	if Input.is_action_just_pressed("punch"):
		_execute_move("punch")

	# Check for kick input
	elif Input.is_action_just_pressed("kick"):
		_execute_move("kick")


func _execute_move(button: String) -> void:
	# Determine the move key based on buffered direction + button
	var move_key := _get_move_key(button)

	# Look up animation in move matrix
	if move_key in move_matrix:
		var animation_name: String = move_matrix[move_key]
		perform_attack(animation_name)
		print("[Player] Execute: %s -> %s" % [move_key, animation_name])
	else:
		print("[Player] WARNING: Move key '%s' not found in matrix!" % move_key)


func _get_move_key(button: String) -> String:
	# Build the move key string based on state and buffered direction
	var key := ""

	# Check if airborne
	var is_airborne := current_state in [State.JUMP, State.FALL]

	if is_airborne:
		# Air attacks
		key = "air_"

		# Use buffered direction for aerial direction (accounting for facing)
		if buffered_direction.x > 0 and is_facing_right:
			key += "forward_"
		elif buffered_direction.x < 0 and not is_facing_right:
			key += "forward_"
		elif buffered_direction.x > 0 and not is_facing_right:
			key += "back_"
		elif buffered_direction.x < 0 and is_facing_right:
			key += "back_"
		else:
			key += "neutral_"
	else:
		# Ground attacks
		# Check vertical direction first (up/down take priority)
		if buffered_direction.y < 0:
			key = "up_"
		elif buffered_direction.y > 0:
			key = "down_"
		# Then horizontal
		elif buffered_direction.x > 0 and is_facing_right:
			key = "forward_"
		elif buffered_direction.x < 0 and not is_facing_right:
			key = "forward_"
		elif buffered_direction.x > 0 and not is_facing_right:
			key = "back_"
		elif buffered_direction.x < 0 and is_facing_right:
			key = "back_"
		else:
			key = "neutral_"

	# Append button
	key += button

	return key


# ============================================================================
# DEBUG HELPERS
# ============================================================================

func _input(event: InputEvent) -> void:
	# Debug: Print input buffer state on attack
	if event.is_action_pressed("punch") or event.is_action_pressed("kick"):
		print("[Player] Input Buffer: dir=%s, timer=%d, facing_right=%s" % [
			buffered_direction,
			direction_buffer_timer,
			is_facing_right
		])
