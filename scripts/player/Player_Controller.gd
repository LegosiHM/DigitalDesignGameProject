extends CharacterBody2D
enum {IDLE, WALK, JUMP, FALL, LEDGE_GRAB}
enum jump_directions {UP = -1, DOWN = 1}
@onready var collision_holder = $CollisionHolder
@onready var collision_shape = $PlayerHitbox
@onready var grab_hand_rayCast = $CollisionHolder/GrabHandRayCast
@onready var grab_check_rayCast = $CollisionHolder/GrabCheckRayCast
@onready var slowFall_hand_rayCast = $CollisionHolder/SlowFallHandRayCast
@onready var slowFall_check_rayCast = $CollisionHolder/SlowFallCheckRayCast
@export var joystick_movement := false
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var animation_state: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/playback")
@export_group("Movement Values")
@export_range(0, 10000, 0.1) var acceleration: float = 700.0
@export_range(0, 10000, 0.1) var max_speed: float = 600.0
@export_range(0, 10000, 0.1) var friction: float = 5000.0
@export_range(0, 1000, 0.1) var air_resistence: float = 200.0
@export_range(0, 10000, 0.1) var gravity: float = 5000.0
@export_range(0, 10000, 0.1) var jump_force: float = 1700.0
@export_range(0, 10000, 0.1) var jump_cancel_force: float = 5000.0
@export_range(0, 1, 0.01) var coyote_timer: float = 0.07
@export_range(0, 1, 0.01) var jump_buffer_timer: float = 0.15
@export var apex_speed_boost: float = 1.2
@export var apex_gravity_modifier: float = 0.5
@export var apex_duration: float = 0.3
var is_grabbing = false
var state: int = IDLE
var can_jump := false
var should_jump := false
var jumping := false
var apex_active: bool = false
var is_slowFalling: bool = false
var ledge_grab_cooldown := false
var slowFall_cooldown := false
var max_energy: int = 200
var threshold_energy: float = max_energy/2.5
var current_energy: int = max_energy
var restore_energy: bool = true
var is_dragging_panel: bool = false

func _physics_process(delta: float) -> void:
	restore_energy_process()
	
	var inputs: Dictionary = get_inputs()
	handle_jump(delta, inputs.input_direction, inputs.jump_strength, inputs.jump_pressed, inputs.jump_released)
	apply_horizontal_movement(delta, inputs.input_direction)
	manage_animations()
	handle_gravity(delta)
	move_and_slide()
	
	_check_fall_behavior()
	if is_grabbing:
		velocity = Vector2.ZERO
		if Input.is_action_just_pressed("jump"):
			is_grabbing = false
			velocity.y = -jump_force  # Jump up from ledge
			animation_player.stop()
			animation_tree.active = true
			return
		if Input.is_action_just_pressed("up"):
			is_grabbing = false
			position.y -= 5  # Climb up ledge
			animation_player.stop()
			animation_tree.active = true
			return
		return
	elif is_slowFalling:
		velocity = Vector2.ZERO
		if Input.is_action_just_pressed("jump"):
			velocity.y = -jump_force  # Jump up from ledge
			is_slowFalling = false
			animation_player.stop()
			animation_tree.active = true
			return
		if Input.is_action_just_pressed("up"):
			position.y -= 5  # Climb up ledge
			is_slowFalling = false
			animation_player.stop()
			animation_tree.active = true
			return
		return

func _check_fall_behavior():
	var is_falling = velocity.y >= 0
	var ledgeGrab_handClear = not grab_hand_rayCast.is_colliding()
	var ledgeGrab_ledgeDetected = grab_check_rayCast.is_colliding()
	var can_grab = is_falling and ledgeGrab_handClear and ledgeGrab_ledgeDetected and not is_grabbing and not ledge_grab_cooldown
	var slowFall_handClear = slowFall_hand_rayCast.is_colliding()
	var slowFall_ledgeDetected = slowFall_check_rayCast.is_colliding()
	var should_slowFall = slowFall_handClear and slowFall_ledgeDetected and not slowFall_cooldown
	if can_grab:
		is_grabbing = true
		state = LEDGE_GRAB
		velocity = Vector2.ZERO  # Stop movement
		start_ledgeGrab_cooldown()
		return
	elif should_slowFall:
		is_slowFalling = true
		velocity = Vector2.ZERO  # Stop movement
		start_slowFall_cooldown()
		return

func manage_animations() -> void:
	if is_grabbing:
		if animation_tree.active:  # Disable AnimationTree to stop unwanted animations
			animation_tree.active = false
		if not animation_player.is_playing():
			animation_player.play("ledge_grab")  # Play ledge grab animation
		return  # Stop further execution to prevent AnimationTree from running
	elif is_slowFalling:
		if animation_tree.active:  # Disable AnimationTree to stop unwanted animations
			animation_tree.active = false
		if not animation_player.is_playing():
			animation_player.play("slow_fall")  # Play ledge grab animation
		return
	if not animation_tree.active:
		animation_tree.active = true  # Re-enable AnimationTree
	animation_player.stop()  # Stop ledge grab animation
	if is_on_floor():
		if velocity.x == 0:
			animation_state.travel("idle")
		else:
			animation_state.travel("RunBlend")
		var direction = sign(velocity.x)
		animation_tree.set("parameters/RunBlend/blend_position", direction)
	if velocity.x > 0:
		collision_holder.position.x = abs(collision_holder.position.x)  # Keep RayCasts on right
		collision_shape.position.x = abs(collision_shape.position.x)  # Keep Collision on right
		_flip_raycast_direction(1)  # Face right
	elif velocity.x < 0:
		collision_holder.position.x = -abs(collision_holder.position.x)  # Move RayCasts left
		collision_shape.position.x = -abs(collision_shape.position.x)  # Move Collision left
		_flip_raycast_direction(-1)  # Face left

func _flip_raycast_direction(direction: int):
	grab_hand_rayCast.target_position.x = abs(grab_hand_rayCast.target_position.x) * direction
	grab_check_rayCast.target_position.x = abs(grab_check_rayCast.target_position.x) * direction
	slowFall_hand_rayCast.target_position.x = abs(slowFall_hand_rayCast.target_position.x) * direction
	slowFall_check_rayCast.target_position.x = abs(slowFall_check_rayCast.target_position.x) * direction

func apply_horizontal_movement(delta: float, input_direction: Vector2 = Vector2.ZERO) -> void:
	if is_grabbing:
		velocity.x = 0
		return
	if input_direction.x != 0:
		apply_velocity(delta, input_direction)
	else:
		apply_friction(delta)

func handle_gravity(delta: float) -> void:
	if is_grabbing:
		return
	velocity.y += gravity * delta
	if not is_on_floor() and can_jump:
		coyote_time()

func handle_jump(delta: float, move_direction: Vector2, jump_strength: float = 0.0, jump_pressed: bool = false, _jump_released: bool = false) -> void:
	if (jump_pressed or should_jump) and can_jump:
		apply_jump(move_direction)
	elif jump_pressed:
		buffer_jump()
	elif jump_strength == 0 and velocity.y < 0:
		cancel_jump(delta)
	if is_on_floor() and velocity.y >= 0:
		can_jump = true
		jumping = false

func apply_jump(_move_direction: Vector2, jump_direction: int = jump_directions.UP) -> void:
	can_jump = false
	should_jump = false
	jumping = true
	velocity.y += jump_force * jump_direction

func get_inputs() -> Dictionary:
	return {
		input_direction = get_input_direction(),
		jump_strength = Input.get_action_strength("jump"),
		jump_pressed = Input.is_action_just_pressed("jump"),
		jump_released = Input.is_action_just_released("jump"),
	}

func get_input_direction() -> Vector2:
	var x_dir: float = Input.get_action_strength("right") - Input.get_action_strength("left")
	var y_dir: float = Input.get_action_strength("down") - Input.get_action_strength("up")
	return Vector2(x_dir if joystick_movement else sign(x_dir), y_dir if joystick_movement else sign(y_dir))

func apply_velocity(delta: float, move_direction: Vector2) -> void:
	velocity.x += move_direction.x * acceleration * delta
	velocity.x = clamp(velocity.x, -max_speed * abs(move_direction.x), max_speed * abs(move_direction.x))

func cancel_jump(delta: float) -> void:
	jumping = false
	velocity.y -= jump_cancel_force * sign(velocity.y) * delta

func buffer_jump() -> void:
	should_jump = true
	await get_tree().create_timer(jump_buffer_timer).timeout
	should_jump = false

func coyote_time() -> void:
	await get_tree().create_timer(coyote_timer).timeout
	can_jump = false

func apply_apex_modifier(_delta: float) -> void:
	if not apex_active and abs(velocity.y) < 10:
		apex_active = true
		velocity.x *= apex_speed_boost
		gravity *= apex_gravity_modifier
		await get_tree().create_timer(apex_duration).timeout
		reset_apex_modifier()

func reset_apex_modifier() -> void:
	apex_active = false
	gravity /= apex_gravity_modifier

func apply_friction(delta: float) -> void:
	var fric: float = friction * delta * sign(velocity.x) * -1 if is_on_floor() else air_resistence * delta * sign(velocity.x) * -1
	if abs(velocity.x) <= abs(fric):
		velocity.x = 0
	else:
		velocity.x += fric

func start_ledgeGrab_cooldown():
	ledge_grab_cooldown = true
	await get_tree().create_timer(0.7).timeout  # Adjust cooldown duration as needed
	ledge_grab_cooldown = false

func start_slowFall_cooldown():
	slowFall_cooldown = true
	await get_tree().create_timer(1.0).timeout  # Adjust cooldown duration as needed
	slowFall_cooldown = false

func restore_energy_process():
	if is_dragging_panel:
		return
	if current_energy < max_energy:  # Ensure energy restores only when below max
		current_energy += 1

func consume_energy(amount: int) -> bool:
	if current_energy >= amount:
		current_energy -= amount
		return true  # Energy was successfully consumed
	else:
		restore_energy = true  # Ensure energy starts restoring when empty
		return false  # Not enough energy
