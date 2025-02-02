class_name PlatformerController
extends CharacterBody2D

## Character States
enum {IDLE, WALK, JUMP, FALL, LEDGE_GRAB}  # WALL_SLIDE removed

## Jump Directions
enum JUMP_DIRECTIONS {UP = -1, DOWN = 1}

## Nodes and Components
@export_node_path("Sprite2D") var PLAYER_SPRITE_PATH: NodePath
@onready var PLAYER_SPRITE: Sprite2D = get_node(PLAYER_SPRITE_PATH) if PLAYER_SPRITE_PATH else $Sprite2D
@onready var COLLISION_HOLDER = $CollisionHolder
@onready var COLLISION_SHAPE = $PlayerHitbox
@onready var grab_hand_ray_cast = $CollisionHolder/GrabHandRayCast
@onready var grab_check_ray_cast = $CollisionHolder/GrabCheckRayCast


## Input Actions
@export var ACTION_UP := "up"
@export var ACTION_DOWN := "down"
@export var ACTION_LEFT := "left"
@export var ACTION_RIGHT := "right"
@export var ACTION_JUMP := "jump"
@export var ACTION_SPRINT := "sprint"
@export var ACTION_GRAB := "vi_accept"

## Movement Variables
@export var ACCELERATION: float = 500.0
@export var MAX_SPEED: float = 100.0
@export var SPRINT_MULTIPLIER: float = 1.5
@export var FRICTION: float = 500.0
@export var AIR_RESISTANCE: float = 200.0
@export var GRAVITY: float = 500.0
@export var JUMP_FORCE: float = 200.0
@export var JUMP_CANCEL_FORCE: float = 800.0
@export var COYOTE_TIMER: float = 0.08
@export var JUMP_BUFFER_TIMER: float = 0.1

## Ledge Grab Properties
var isGrabbing = false
var isLocked = false
var can_jump = false
var should_jump = false
var jumping = false
var state: int = IDLE

func _ready():
	# Ensure CollisionHolder starts facing the correct direction
	COLLISION_HOLDER.scale.x = 1

func _physics_process(delta: float) -> void:
	if isLocked:
		return
	
	_check_ledge_grab()

	# If grabbing a ledge, allow climbing or jumping
	if isGrabbing:
		velocity = Vector2.ZERO
		if Input.is_action_just_pressed(ACTION_JUMP):
			isGrabbing = false
			velocity.y = -JUMP_FORCE  # Jump up from ledge
			print("Jumping from ledge!")
		if Input.is_action_just_pressed(ACTION_UP):
			isGrabbing = false
			position.y -= 5  # Climb up ledge
			print("Climbing up ledge!")
		return
	
	_apply_movement(delta)
	move_and_slide()

## Ledge Grabbing Detection
func _check_ledge_grab():
	# Debugging output to verify detection
	print("Checking ledge grab...")
	print(" - Falling:", velocity.y >= 0)
	print(" - Hand Free:", not grab_hand_ray_cast.is_colliding())
	print(" - Ledge Found:", grab_check_ray_cast.is_colliding())

	# Check if the player is falling and a ledge is detected
	var isFalling = velocity.y >= 0
	var handClear = not grab_hand_ray_cast.is_colliding()
	var ledgeDetected = grab_check_ray_cast.is_colliding()
	var canGrab = isFalling and handClear and ledgeDetected and not isGrabbing

	# If ledge grab is possible, enter grab state
	if canGrab:
		isGrabbing = true
		state = LEDGE_GRAB
		velocity = Vector2.ZERO  # Stop movement
		print("✅ Ledge grabbed!")

## Apply movement and physics
func _apply_movement(delta: float) -> void:
	var input_direction = get_input_direction()
	handle_jump(delta, input_direction, Input.is_action_just_pressed(ACTION_JUMP))
	handle_gravity(delta)
	handle_velocity(delta, input_direction)
	manage_state()
	manage_animations()

## Jumping Mechanics
func handle_jump(delta: float, move_direction: Vector2, jump_pressed: bool = false) -> void:
	if isLocked:
		return
	
	if jump_pressed and can_jump:
		apply_jump(move_direction)
	elif jump_pressed:
		buffer_jump()
	
	if is_on_floor() and velocity.y >= 0:
		can_jump = true
		jumping = false

func apply_jump(move_direction: Vector2, jump_force: float = JUMP_FORCE) -> void:
	can_jump = false
	should_jump = false
	jumping = true
	velocity.y -= jump_force

## Gravity Handling (No More Wall Slide)
func handle_gravity(delta: float) -> void:
	velocity.y += GRAVITY * delta
	
	if not is_on_floor() and can_jump:
		coyote_time()

## Movement Handling
func handle_velocity(delta: float, input_direction: Vector2) -> void:
	if isLocked:
		return
	
	if input_direction.x != 0:
		apply_velocity(delta, input_direction)
	else:
		apply_friction(delta)

func apply_velocity(delta: float, move_direction: Vector2) -> void:
	velocity.x += move_direction.x * ACCELERATION * delta
	velocity.x = clamp(velocity.x, -MAX_SPEED, MAX_SPEED)

func apply_friction(delta: float) -> void:
	var fric: float = FRICTION * delta if is_on_floor() else AIR_RESISTANCE * delta
	velocity.x = move_toward(velocity.x, 0, fric)

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
		PLAYER_SPRITE.flip_h = false
		COLLISION_HOLDER.position.x = abs(COLLISION_HOLDER.position.x)  # Keep RayCasts on right
		COLLISION_SHAPE.position.x = abs(COLLISION_SHAPE.position.x)  # Keep Collision on right
		_flip_raycast_direction(1)  # Face right
	elif velocity.x < 0:
		PLAYER_SPRITE.flip_h = true
		COLLISION_HOLDER.position.x = -abs(COLLISION_HOLDER.position.x)  # Move RayCasts left
		COLLISION_SHAPE.position.x = -abs(COLLISION_SHAPE.position.x)  # Move Collision left
		_flip_raycast_direction(-1)  # Face left



## Utility Functions
func get_input_direction() -> Vector2:
	var x_dir: float = Input.get_action_strength(ACTION_RIGHT) - Input.get_action_strength(ACTION_LEFT)
	var y_dir: float = Input.get_action_strength(ACTION_DOWN) - Input.get_action_strength(ACTION_UP)
	return Vector2(sign(x_dir), sign(y_dir))

func buffer_jump() -> void:
	should_jump = true
	await get_tree().create_timer(JUMP_BUFFER_TIMER).timeout
	should_jump = false

func coyote_time() -> void:
	await get_tree().create_timer(COYOTE_TIMER).timeout
	can_jump = false

func _flip_raycast_direction(direction: int):
	# Get RayCasts from CollisionHolder
	var grab_hand_ray_cast = $CollisionHolder/GrabHandRayCast
	var grab_check_ray_cast = $CollisionHolder/GrabCheckRayCast

	# Flip RayCasts manually
	grab_hand_ray_cast.target_position.x = abs(grab_hand_ray_cast.target_position.x) * direction
	grab_check_ray_cast.target_position.x = abs(grab_check_ray_cast.target_position.x) * direction
