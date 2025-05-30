extends CharacterBody2D

# ------------------------------------------------------------------------------
# ENUMS FOR STATE MANAGEMENT
# ------------------------------------------------------------------------------

enum { IDLE, WALK, JUMP, FALL, LEDGE_GRAB }
enum jump_directions { UP = -1, DOWN = 1 }

# ------------------------------------------------------------------------------
# NODE REFERENCES
# ------------------------------------------------------------------------------

@onready var collision_holder = $CollisionHolder
@onready var collision_shape = $PlayerHitbox
@onready var grab_hand_rayCast = $CollisionHolder/GrabHandRayCast
@onready var grab_check_rayCast = $CollisionHolder/GrabCheckRayCast
@onready var slowFall_hand_rayCast = $CollisionHolder/SlowFallHandRayCast
@onready var slowFall_check_rayCast = $CollisionHolder/SlowFallCheckRayCast

# ------------------------------------------------------------------------------
# PLAYER CONTROL OPTIONS
# ------------------------------------------------------------------------------

@export var joystick_movement := false

# ------------------------------------------------------------------------------
# MOVEMENT VALUES
# ------------------------------------------------------------------------------

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

# ------------------------------------------------------------------------------
# MOTORCYCLE BOOST SETTINGS
# ------------------------------------------------------------------------------

@export_group("Motorcycle Boost Settings")
@export var boost_multiplier: float = 1.5
@export var boost_decay_speed: float = 8.0

# ------------------------------------------------------------------------------
# AUDIO STREAM PLAYERS (SFX)
# ------------------------------------------------------------------------------

@onready var audio_jump = $AudioManager/Audio_Jump
@onready var audio_land = $AudioManager/Audio_Land
@onready var audio_ledge_grab = $AudioManager/Audio_LedgeGrab
@onready var audio_slow_fall = $AudioManager/Audio_SlowFall
@onready var audio_walk_start = $AudioManager/Audio_WalkStart
@onready var audio_game_over = $AudioManager/Audio_GameOver
@onready var audio_dragging = $AudioManager/Audio_Dragging
@onready var audio_drag_end = $AudioManager/Audio_DragEnd
@onready var audio_drag_threshold = $AudioManager/Audio_DragThreshold
@onready var audio_drag_fully_replenish = $AudioManager/Audio_DragFullyReplenish
@onready var audio_illegal_drag = $AudioManager/Audio_IllegalDrag
@onready var audio_hypnotize_before = $AudioManager/Audio_HypnotizeBefore
@onready var audio_hypnotize_after = $AudioManager/Audio_HypnotizeAfter
@onready var audio_npc_talking = $AudioManager/Audio_NPCTalking
@onready var audio_panel_reveal = $AudioManager/Audio_PanelReveal
@onready var audio_respawn = $AudioManager/Audio_Respawn
@onready var audio_changescene = $AudioManager/Audio_ChangeScene

# ------------------------------------------------------------------------------
# INTERNAL STATE VARIABLES
# ------------------------------------------------------------------------------

var is_grabbing = false
var state: int = IDLE
var can_jump := false
var should_jump := false
var jumping := false
var apex_active: bool = false
var is_slowFalling: bool = false
var ledge_grab_cooldown := false
var slowFall_cooldown := false
var facing_direction := 1

var current_platform_velocity := Vector2.ZERO
var touching_panels := []
var sprite_original_offset := Vector2.ZERO

var input_enabled: bool = true # If false, input is ignored (used for respawn delay)

var walk_input_started := false # Used to trigger walk start SFX only once
var was_dragging_panel := false # Used to track dragging state change for SFX

var was_on_floor := false


# ------------------------------------------------------------------------------
# ENERGY SYSTEM
# ------------------------------------------------------------------------------

var max_energy: int = 200
var threshold_energy: float = max_energy / 2.5
var current_energy: int = max_energy
var restore_energy: bool = true
var is_dragging_panel: bool = false

# ------------------------------------------------------------------------------
# READY & PHYSICS LOOP
# ------------------------------------------------------------------------------

func _ready() -> void:
	sprite_original_offset = $AnimatedSprite2D_1.position

func _physics_process(delta: float) -> void:
	restore_energy_process()
	manage_animations()
	handle_gravity(delta)

	if not input_enabled:
		play_anim("default")
		return
	
	# ------------------------------------------------------------------------------
	# WALK START SOUND (IMMEDIATE ON INPUT)
	# ------------------------------------------------------------------------------
	if is_on_floor():
		if not walk_input_started and (Input.is_action_pressed("left") or Input.is_action_pressed("right")):
			if Input.is_action_just_pressed("left") or Input.is_action_just_pressed("right"):
				audio_walk_start.play()
				walk_input_started = true

		if walk_input_started and is_on_floor() and not (Input.is_action_pressed("left") or Input.is_action_pressed("right")):
			audio_walk_start.stop()
			walk_input_started = false
	
	else:
		# In air: make sure walk sound is not playing
		if walk_input_started:
			audio_walk_start.stop()
			walk_input_started = false


	var inputs: Dictionary = get_inputs()
	handle_jump(delta, inputs.input_direction, inputs.jump_strength, inputs.jump_pressed, inputs.jump_released)
	apply_horizontal_movement(delta, inputs.input_direction)

	for panel in touching_panels:
		if panel.returning and panel.has_method("get_motion_delta") and is_on_floor():
			var motion = panel.get_motion_delta(delta)
			var platform_velocity = motion / delta
			platform_velocity = platform_velocity.clamp(Vector2(-62, -62), Vector2(62, 62))
			velocity += platform_velocity
			break
	
	move_and_slide()
	# ✅ Detect landing and check for ongoing walk input
	if is_on_floor() and not was_on_floor:
		if Input.is_action_pressed("left") or Input.is_action_pressed("right"):
			if not walk_input_started:
				audio_walk_start.play()
				walk_input_started = true
	
	if is_on_solid_ground():
		if is_slowFalling:
			is_slowFalling = false
			audio_slow_fall.stop()
		if velocity.x == 0:
			play_anim("default")
	
	_check_fall_behavior()
	
	# Handle ledge grab logic
	if is_grabbing:
		velocity = Vector2.ZERO
		if Input.is_action_just_pressed("jump"):
			is_grabbing = false
			$AnimatedSprite2D_1.position = sprite_original_offset
			velocity.y = -jump_force
			audio_slow_fall.stop()
			return
		if Input.is_action_just_pressed("up"):
			is_grabbing = false
			position.y -= 5
			$AnimatedSprite2D_1.position = sprite_original_offset
			audio_slow_fall.stop()
			return
		return
	
	# Handle slow fall logic
	elif is_slowFalling:
		velocity = Vector2.ZERO
		if not audio_slow_fall.playing:
			audio_slow_fall.play()
		if Input.is_action_just_pressed("jump"):
			velocity.y = -jump_force
			is_slowFalling = false
			audio_slow_fall.stop()
			return
		if Input.is_action_just_pressed("up"):
			position.y -= 5
			is_slowFalling = false
			audio_slow_fall.stop()
			return
		return
	
	# Update facing direction
	if velocity.x > 0:
		facing_direction = 1
	elif velocity.x < 0:
		facing_direction = -1
	
	current_platform_velocity = Vector2.ZERO
	
	was_on_floor = is_on_floor()

# ------------------------------------------------------------------------------
# INPUT HELPERS
# ------------------------------------------------------------------------------

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
	return Vector2(
		x_dir if joystick_movement else sign(x_dir),
		y_dir if joystick_movement else sign(y_dir)
	)

# ------------------------------------------------------------------------------
# FALL BEHAVIOR (LEDGE GRAB / SLOW FALL)
# ------------------------------------------------------------------------------

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
		audio_ledge_grab.play()
		state = LEDGE_GRAB
		velocity = Vector2.ZERO
		start_ledgeGrab_cooldown()
		return
	elif should_slowFall:
		is_slowFalling = true
		velocity = Vector2.ZERO
		start_slowFall_cooldown()
		return

# ------------------------------------------------------------------------------
# ANIMATION CONTROL
# ------------------------------------------------------------------------------

func manage_animations() -> void:
	var sprite = $AnimatedSprite2D_1

	# Determine direction and flip visuals
	if velocity.x > 0:
		facing_direction = 1
	elif velocity.x < 0:
		facing_direction = -1

	sprite.flip_h = facing_direction < 0
	_flip_raycast_direction(facing_direction)
	collision_holder.position.x = abs(collision_holder.position.x) * facing_direction
	collision_shape.position.x = abs(collision_shape.position.x) * facing_direction

	# Reset sprite position unless grabbing
	if not is_grabbing:
		$AnimatedSprite2D_1.position = sprite_original_offset

	# Animation priorities
	if is_grabbing:
		sprite.position = sprite_original_offset + Vector2(facing_direction * 12, 0)
		play_anim("ledge_grab")
		return
	elif is_slowFalling:
		play_anim("slow_falling")
		return

	if not is_on_floor():
		if velocity.y < -10:
			play_anim("jump")
		else:
			play_anim("landing")
			if not is_grabbing or not is_slowFalling:
				audio_land.play()
	elif abs(velocity.x) > 10:
		if get_input_direction().x != 0:
			play_anim("run")
		else:
			play_anim("default")
	else:
		play_anim("default")

func _flip_raycast_direction(direction: int):
	grab_hand_rayCast.target_position.x = abs(grab_hand_rayCast.target_position.x) * direction
	grab_check_rayCast.target_position.x = abs(grab_check_rayCast.target_position.x) * direction
	slowFall_hand_rayCast.target_position.x = abs(slowFall_hand_rayCast.target_position.x) * direction
	slowFall_check_rayCast.target_position.x = abs(slowFall_check_rayCast.target_position.x) * direction

# ------------------------------------------------------------------------------
# JUMP AND GRAVITY SYSTEM
# ------------------------------------------------------------------------------

func apply_horizontal_movement(delta: float, input_direction: Vector2 = Vector2.ZERO) -> void:
	if is_grabbing:
		velocity.x = 0
		return

	if input_direction.x != 0:
		apply_velocity(0.1, input_direction)  # Make it snappy
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
	audio_jump.play()

func apply_velocity(delta: float, move_direction: Vector2) -> void:
	velocity.x += move_direction.x * acceleration * delta
	var boosted_speed = max_speed * boost_multiplier
	if abs(velocity.x) > max_speed:
		velocity.x = lerp(velocity.x, max_speed * sign(velocity.x), boost_decay_speed * delta)
	velocity.x = clamp(velocity.x, -boosted_speed, boosted_speed)

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

# ------------------------------------------------------------------------------
# APEX MODIFIER (Optional Boost at Jump Apex)
# ------------------------------------------------------------------------------

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


# ------------------------------------------------------------------------------
# ENERGY SYSTEM
# ------------------------------------------------------------------------------

func restore_energy_process():
	# Detect transition: not dragging → dragging
	if is_dragging_panel and not was_dragging_panel:
		audio_dragging.play()

	# Detect transition: dragging → not dragging
	elif not is_dragging_panel and was_dragging_panel:
		if audio_dragging.playing:
			audio_dragging.stop()
		audio_drag_end.play()

	# Replenish energy (and maybe play replenish SFX)
	if not is_dragging_panel and current_energy < max_energy:
		var was_above_threshold := current_energy >= threshold_energy
		current_energy += 5
	
		if current_energy >= max_energy:
			audio_drag_fully_replenish.play()
		
		elif current_energy >= threshold_energy and not was_above_threshold:
			audio_drag_threshold.play()

	# Update state at the end of frame
	was_dragging_panel = is_dragging_panel


func consume_energy(amount: int) -> bool:
	if current_energy >= amount:
		current_energy -= amount
		return true
	else:
		restore_energy = true
		return false

# ------------------------------------------------------------------------------
# PLATFORM INTERACTIONS
# ------------------------------------------------------------------------------

func is_on_solid_ground() -> bool:
	return $CollisionHolder/GroundRay.is_colliding()

func _on_platform_entered(area: Area2D) -> void:
	if area.is_in_group("draggable_panels"):
		touching_panels.append(area)

func _on_platform_exited(area: Area2D) -> void:
	if area.is_in_group("draggable_panels"):
		touching_panels.erase(area)

# ------------------------------------------------------------------------------
# LEDGE GRAB / SLOW FALL COOLDOWN
# ------------------------------------------------------------------------------

func start_ledgeGrab_cooldown():
	ledge_grab_cooldown = true
	await get_tree().create_timer(0.7).timeout
	ledge_grab_cooldown = false

func start_slowFall_cooldown():
	slowFall_cooldown = true
	await get_tree().create_timer(1.0).timeout
	slowFall_cooldown = false

# ------------------------------------------------------------------------------
# POWER-UP SYSTEM (HJ)
# ------------------------------------------------------------------------------

func apply_hj_power() -> void:
	Global.has_hj_power = true

# ------------------------------------------------------------------------------
# PLAY ANIMATION
# ------------------------------------------------------------------------------

# Plays the correct animation based on current state and HJ power
func play_anim(anim_name: String):
	var suffix := "HJ" if Global.has_hj_power else ""
	$AnimatedSprite2D_1.play(anim_name + suffix)

# ------------------------------------------------------------------------------
# APPLY FRICTION
# ------------------------------------------------------------------------------

# This handles friction when the player is not providing directional input.
# It reduces the player's velocity based on ground or air resistance.
func apply_friction(delta: float) -> void:
	var resistance: float = friction if is_on_floor() else air_resistence
	var fric: float = resistance * delta * sign(velocity.x) * -1  # Opposes motion

	# Stop movement if friction would reverse velocity
	if abs(velocity.x) <= abs(fric):
		velocity.x = 0
	else:
		velocity.x += fric

# -------------------------------------------------------------------
# PUBLIC METHODS TO PLAY DIALOG-RELATED SFX
# -------------------------------------------------------------------

func play_npc_talking():
	if audio_npc_talking and not audio_npc_talking.playing:
		audio_npc_talking.play()

func stop_npc_talking():
	if audio_npc_talking and audio_npc_talking.playing:
		audio_npc_talking.stop()

func play_panel_reveal():
	if audio_panel_reveal:
		audio_panel_reveal.play()
