extends Area2D

# ------------------------------------------------------------------------------
# EXPORT SETTINGS (Tunable from Inspector)
# ------------------------------------------------------------------------------

@export var return_speed: float = 150.0  # Speed when returning to original position
@export var illegalDragging_speed: float = 30.0  # Speed while being dragged over a forbidden area
@export var normalDragging_speed: float = 1000.0  # Normal drag speed
@export var energyConsumption: int = 1  # Base energy cost to drag
@export var untouchable: bool = false  # If true, triggers respawn when overlapping
@export var stuckOnCollider: bool = false  # If true, returns forcibly when overlapping with obstacle

# ------------------------------------------------------------------------------
# INTERNAL STATE VARIABLES
# ------------------------------------------------------------------------------

var dragging: bool = false  # Is the panel currently being dragged
var collide: bool = false  # True if overlapping with any area
var offset: Vector2 = Vector2.ZERO  # Mouse offset during drag
var original_position: Vector2 = Vector2.ZERO  # Where the panel starts
var returning: bool = false  # Is it returning to original position
var velocity: Vector2 = Vector2.ZERO  # Velocity of the panel
var effect_running: bool = false  # If a blur/respawn effect is ongoing
var last_position: Vector2 = Vector2.ZERO  # Used to calculate motion delta

# ------------------------------------------------------------------------------
# REFERENCES TO OTHER NODES
# ------------------------------------------------------------------------------

@onready var player = get_tree().current_scene.get_node("Player")  # Reference to player
var respawn_manager  # Node handling respawn
var respawn_position  # Position to respawn player to

# ------------------------------------------------------------------------------
# READY: Initialize variables and node references
# ------------------------------------------------------------------------------

func _ready() -> void:
	original_position = global_position
	last_position = global_position
	respawn_manager = get_tree().current_scene.get_node("RespawnDetector")
	respawn_position = respawn_manager.respawn_position  # Where the player will respawn

# ------------------------------------------------------------------------------
# PROCESS: Main logic each frame
# ------------------------------------------------------------------------------

func _process(delta: float) -> void:
	check_overlap_area()

	var player_position = player.global_position
	
	if untouchable:
		if collide:
			respawn_with_effect()

	if dragging:
		var energy_needed = energyConsumption * (2 if collide else 1)

		# Abort drag if player runs out of energy
		if not player.consume_energy(energy_needed):
			dragging = false
			returning = true
			return

		var new_position = get_global_mouse_position() - offset
		velocity = new_position - global_position
		var move_speed = illegalDragging_speed if collide else normalDragging_speed
		global_position = global_position.move_toward(new_position, move_speed * delta)

	elif returning:
		var previous_position = global_position

		# If stuck, force move back with double step
		if stuckOnCollider:
			if collide:
				global_position = global_position.move_toward(original_position, return_speed * delta)
				global_position = global_position.move_toward(original_position, -return_speed * delta)
			else:
				global_position = global_position.move_toward(original_position, return_speed * delta)
		else:
			global_position = global_position.move_toward(original_position, return_speed * delta)

		velocity = (global_position - previous_position) / delta

		if global_position.distance_to(original_position) < 1.0:
			returning = false
			global_position = original_position
			velocity = Vector2.ZERO

# ------------------------------------------------------------------------------
# BUTTON SIGNALS: Drag Start and End
# ------------------------------------------------------------------------------

func _on_button_button_down() -> void:
	if player.current_energy < player.threshold_energy:
		return  # Player doesn't have enough energy to begin drag

	dragging = true
	returning = false
	offset = get_global_mouse_position() - global_position
	player.is_dragging_panel = true

func _on_button_button_up() -> void:
	dragging = false
	returning = true
	player.is_dragging_panel = false

# ------------------------------------------------------------------------------
# COLLISION CHECKER
# ------------------------------------------------------------------------------

func check_overlap_area():
	collide = has_overlapping_areas()

# ------------------------------------------------------------------------------
# RESPAWN EFFECT + TELEPORT LOGIC
# ------------------------------------------------------------------------------

func respawn_with_effect():
	effect_running = true
	var blur_effect = $"../CanvasLayer/Respawn_Effect"
	var material := blur_effect.material as ShaderMaterial

	blur_effect.visible = true

	var tween := get_tree().create_tween()
	respawn_timer()  # Teleport the player
	tween.tween_property(material, "shader_parameter/height", 1.0, 0.7)
	tween.tween_property(material, "shader_parameter/height", -1.0, 0.7)
	await tween.finished

	blur_effect.visible = false
	effect_running = false

func respawn_timer():
	await get_tree().create_timer(0.1).timeout
	player.global_position = respawn_position

# ------------------------------------------------------------------------------
# MOTION HELPER METHODS
# ------------------------------------------------------------------------------

func get_velocity() -> Vector2:
	return velocity

func get_motion_delta(delta: float) -> Vector2:
	var motion = global_position - last_position
	last_position = global_position
	return motion
