class_name PlatformerController
extends CharacterBody2D

## Character's state
enum {IDLE, WALK, JUMP, FALL, LEDGE_GRAB}

## The values for the jump direction, default is UP or -1
enum JUMP_DIRECTIONS {UP = -1, DOWN = 1}

@onready var COLLISION_HOLDER = $CollisionHolder
@onready var COLLISION_SHAPE = $PlayerHitbox
@onready var grab_hand_ray_cast = $CollisionHolder/GrabHandRayCast
@onready var grab_check_ray_cast = $CollisionHolder/GrabCheckRayCast
@onready var slow_fall_hand_raycast = $CollisionHolder/SlowFallHandRayCast
@onready var slow_fall_check_raycast = $CollisionHolder/SlowFallCheckRayCast

## Enables/Disables hard movement when using a joystick.  When enabled, slightly moving the joystick
## will only move the character at a percentage of the maximum acceleration and speed instead of the maximum.
@export var JOYSTICK_MOVEMENT := false

## Enable/Disable sprinting
@export var ENABLE_SPRINT := false

# 🎬 AnimationTree Setup
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var animation_state: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/playback")

@export_group("Input Map Actions")
@export var ACTION_UP := "up"
@export var ACTION_DOWN := "down"
@export var ACTION_LEFT := "left"
@export var ACTION_RIGHT := "right"
@export var ACTION_JUMP := "jump"
@export var ACTION_SPRINT := "sprint"
@export var ACTION_GRAB := "vi_accept"

@export_group("Movement Values")
@export_range(0, 1000, 0.1) var ACCELERATION: float = 500.0
@export_range(0, 1000, 0.1) var MAX_SPEED: float = 100.0
@export_range(0, 10, 0.1) var SPRINT_MULTIPLIER: float = 1.5
@export_range(0, 10000, 0.1) var FRICTION: float = 500.0
@export_range(0, 1000, 0.1) var AIR_RESISTENCE: float = 200.0
@export_range(0, 10000, 0.1) var GRAVITY: float = 500.0
@export_range(0, 10000, 0.1) var JUMP_FORCE: float = 200.0
@export_range(0, 10000, 0.1) var JUMP_CANCEL_FORCE: float = 800.0
@export_range(0, 1, 0.01) var COYOTE_TIMER: float = 0.08
@export_range(0, 1, 0.01) var JUMP_BUFFER_TIMER: float = 0.1
@export var APEX_SPEED_BOOST: float = 1.2
@export var APEX_GRAVITY_MODIFIER: float = 0.5
@export var APEX_DURATION: float = 0.3

## Ledge Grab Properties
var isGrabbing = false
var isLocked = false

## The players current state
var state: int = IDLE
var sprinting := false	
var can_jump := false
var should_jump := false
var jumping := false
var apex_active: bool = false

## Lock movement when required
var is_locked: bool = false

## Platform-related state
var platform: Node = null
var is_on_platform: bool = false

## Handles sprint and wall jump readiness
@onready var can_sprint: bool = ENABLE_SPRINT
var isSlowFalling: bool = false

var ledge_grab_cooldown := false
var slow_fall_cooldown := false

func _ready():
	animation_tree.active = true
	## Ensure the platform connects to the lock_player_movement signal
	if platform:
		platform.connect("lock_player_movement", Callable(self, "_on_lock_player_movement"))
	# Ensure CollisionHolder starts facing the correct direction
	COLLISION_HOLDER.scale.x = 1

func _process(delta):
	var is_moving = abs(velocity.x) > 0.1  # Check if the player is moving
	
	if is_moving:
		animation_state.travel("run")  # Play Run Animation
	else:
		animation_state.travel("idle")  # Keep the sprite static

func _physics_process(delta: float) -> void:
	## Only execute physics logic if not locked
	if not is_locked:
		physics_tick(delta)
		
	if isLocked:
		return
	
	_check_fall_behavior()

	# If grabbing a ledge, allow climbing or jumping
	if isGrabbing:
		velocity = Vector2.ZERO
		if Input.is_action_just_pressed(ACTION_JUMP):
			isGrabbing = false
			velocity.y = -JUMP_FORCE  # Jump up from ledge
			return
		if Input.is_action_just_pressed(ACTION_UP):
			isGrabbing = false
			position.y -= 5  # Climb up ledge
			return
		return
	elif isSlowFalling:
		velocity = Vector2.ZERO
		if Input.is_action_just_pressed(ACTION_JUMP):
			velocity.y = -JUMP_FORCE  # Jump up from ledge
			isSlowFalling = false
			return
		if Input.is_action_just_pressed(ACTION_UP):
			position.y -= 5  # Climb up ledge
			isSlowFalling = false
			return
		return

var debug_timer := 0.0
## Ledge Grabbing Detection
func _check_fall_behavior():
	var isFalling = velocity.y >= 0
	
	# 🟢 Ledge Grab Logic
	var ledgeGrab_handClear = not grab_hand_ray_cast.is_colliding()
	var ledgeGrab_ledgeDetected = grab_check_ray_cast.is_colliding()
	var canGrab = isFalling and ledgeGrab_handClear and ledgeGrab_ledgeDetected and not isGrabbing and not ledge_grab_cooldown
	
	# 🟡 Slow Fall Logic
	var slowFall_handClear = slow_fall_hand_raycast.is_colliding()
	var slowFall_ledgeDetected = slow_fall_check_raycast.is_colliding()
	var shouldSlowFall = slowFall_handClear and slowFall_ledgeDetected and not slow_fall_cooldown
	# If ledge grab is possible, enter grab state
	if canGrab:
		isGrabbing = true
		state = LEDGE_GRAB
		velocity = Vector2.ZERO  # Stop movement
		start_ledge_grab_cooldown()
		return
	elif shouldSlowFall:
		isSlowFalling = true
		velocity = Vector2.ZERO  # Stop movement
		start_slow_fall_cooldown()
		return

## Overrideable physics process used by the controller that calls whatever functions should be called
## and any logic that needs to be done on the [param _physics_process] tick
func physics_tick(delta: float) -> void:
	var inputs: Dictionary = get_inputs()
	handle_jump(delta, inputs.input_direction, inputs.jump_strength, inputs.jump_pressed, inputs.jump_released)
	handle_sprint(inputs.sprint_strength)
	handle_velocity(delta, inputs.input_direction)

	manage_animations()
	manage_state()
	handle_gravity(delta)

	move_and_slide()

## Callback to lock/unlock player movement
func _on_lock_player_movement(lock: bool) -> void:
	is_locked = lock

## State Management (No More WALL_SLIDE)
func manage_state() -> void:
	if isLocked:
		return

	# PRIORITY: If grabbing a ledge, stay in ledge grab state
	if isGrabbing:
		state = LEDGE_GRAB
		return

	# Handle normal movement states
	if velocity.y == 0:
		if velocity.x == 0:
			state = IDLE
		else:
			state = WALK
	elif velocity.y < 0:
		state = JUMP
	else:
		state = FALL

## Animation Handling (Auto-Flipping Collision & RayCasts)
func manage_animations() -> void:
	if velocity.x > 0:
		COLLISION_HOLDER.position.x = abs(COLLISION_HOLDER.position.x)  # Keep RayCasts on right
		COLLISION_SHAPE.position.x = abs(COLLISION_SHAPE.position.x)  # Keep Collision on right
		_flip_raycast_direction(1)  # Face right
	elif velocity.x < 0:
		COLLISION_HOLDER.position.x = -abs(COLLISION_HOLDER.position.x)  # Move RayCasts left
		COLLISION_SHAPE.position.x = -abs(COLLISION_SHAPE.position.x)  # Move Collision left
		_flip_raycast_direction(-1)  # Face left

func _flip_raycast_direction(direction: int):

	# Flip RayCasts manually
	grab_hand_ray_cast.target_position.x = abs(grab_hand_ray_cast.target_position.x) * direction
	grab_check_ray_cast.target_position.x = abs(grab_check_ray_cast.target_position.x) * direction
	slow_fall_hand_raycast.target_position.x = abs(slow_fall_hand_raycast.target_position.x) * direction
	slow_fall_check_raycast.target_position.x = abs(slow_fall_hand_raycast.target_position.x) * direction

## Movement functions respect the locked state
func handle_velocity(delta: float, input_direction: Vector2 = Vector2.ZERO) -> void:
	if is_locked or isGrabbing:
		velocity.x = 0
		return

	if input_direction.x != 0:
		apply_velocity(delta, input_direction)
	else:
		apply_friction(delta)

func handle_sprint(sprint_strength: float) -> void:
	if sprint_strength != 0 and can_sprint:
		sprinting = true
	else:
		sprinting = false

func handle_gravity(delta: float) -> void:
	if isGrabbing:
		return
	
	velocity.y += GRAVITY * delta
	
	if not is_on_floor() and can_jump:
		coyote_time()

func handle_jump(delta: float, move_direction: Vector2, jump_strength: float = 0.0, jump_pressed: bool = false, _jump_released: bool = false) -> void:
	if is_locked:
		return
	if (jump_pressed or should_jump) and can_jump:
		apply_jump(move_direction)
	elif jump_pressed:
		buffer_jump()
	elif jump_strength == 0 and velocity.y < 0:
		cancel_jump(delta)

	if is_on_floor() and velocity.y >= 0:
		can_jump = true
		jumping = false

func apply_jump(_move_direction: Vector2, jump_force: float = JUMP_FORCE, jump_direction: int = JUMP_DIRECTIONS.UP) -> void:
	can_jump = false
	should_jump = false
	jumping = true

	velocity.y += jump_force * jump_direction

func get_inputs() -> Dictionary:
	return {
		input_direction = get_input_direction(),
		jump_strength = Input.get_action_strength(ACTION_JUMP),
		jump_pressed = Input.is_action_just_pressed(ACTION_JUMP),
		jump_released = Input.is_action_just_released(ACTION_JUMP),
		sprint_strength = Input.get_action_strength(ACTION_SPRINT) if ENABLE_SPRINT else 0.0,
	}

func get_input_direction() -> Vector2:
	var x_dir: float = Input.get_action_strength(ACTION_RIGHT) - Input.get_action_strength(ACTION_LEFT)
	var y_dir: float = Input.get_action_strength(ACTION_DOWN) - Input.get_action_strength(ACTION_UP)

	return Vector2(x_dir if JOYSTICK_MOVEMENT else sign(x_dir), y_dir if JOYSTICK_MOVEMENT else sign(y_dir))

func apply_velocity(delta: float, move_direction: Vector2) -> void:
	var sprint_strength: float = SPRINT_MULTIPLIER if sprinting else 1.0
	velocity.x += move_direction.x * ACCELERATION * delta * (sprint_strength if is_on_floor() else 1.0)
	velocity.x = clamp(velocity.x, -MAX_SPEED * abs(move_direction.x) * sprint_strength, MAX_SPEED * abs(move_direction.x) * sprint_strength)

func cancel_jump(delta: float) -> void:
	jumping = false
	velocity.y -= JUMP_CANCEL_FORCE * sign(velocity.y) * delta
	
## If jump is pressed before hitting the ground, it's buffered using the [param JUMP_BUFFER_TIMER] value and the jump is applied
## if the character lands before the timer ends
func buffer_jump() -> void:
	should_jump = true
	await get_tree().create_timer(JUMP_BUFFER_TIMER).timeout
	should_jump = false


## If the character steps off of a platform, they are given an amount of time in the air to still jump using the [param COYOTE_TIMER] value
func coyote_time() -> void:
	await get_tree().create_timer(COYOTE_TIMER).timeout
	can_jump = false

# Function to handle apex modifier
func apply_apex_modifier(_delta: float) -> void:
	if not apex_active and abs(velocity.y) < 10:
		apex_active = true
		velocity.x *= APEX_SPEED_BOOST
		GRAVITY *= APEX_GRAVITY_MODIFIER
		await get_tree().create_timer(APEX_DURATION).timeout
		reset_apex_modifier()

func reset_apex_modifier() -> void:
	apex_active = false
	GRAVITY /= APEX_GRAVITY_MODIFIER

func apply_friction(delta: float) -> void:
	var fric: float = FRICTION * delta * sign(velocity.x) * -1 if is_on_floor() else AIR_RESISTENCE * delta * sign(velocity.x) * -1
	if abs(velocity.x) <= abs(fric):
		velocity.x = 0
	else:
		velocity.x += fric

func start_ledge_grab_cooldown():
	ledge_grab_cooldown = true
	await get_tree().create_timer(0.7).timeout  # Adjust cooldown duration as needed
	ledge_grab_cooldown = false

func start_slow_fall_cooldown():
	slow_fall_cooldown = true
	await get_tree().create_timer(1.0).timeout  # Adjust cooldown duration as needed
	slow_fall_cooldown = false
