extends Area2D

# ------------------------------------------------------------------------------
# EXPORT VARIABLES (Editable in Inspector)
# ------------------------------------------------------------------------------

@export var respawn_position: Vector2  # The location to move the player to after respawn

# ------------------------------------------------------------------------------
# STATE FLAGS
# ------------------------------------------------------------------------------

var entered := false  # True when the player is inside this Area2D
var effect_running := false  # Prevents respawn from being triggered multiple times

# ------------------------------------------------------------------------------
# SIGNAL CALLBACKS
# ------------------------------------------------------------------------------

# Triggered when the player enters the respawn detection area
func _on_body_entered(_body: PhysicsBody2D) -> void:
	entered = true

# Triggered when the player leaves the respawn detection area
func _on_body_exited(_body: PhysicsBody2D) -> void:
	entered = false

# ------------------------------------------------------------------------------
# MAIN PROCESS LOOP
# ------------------------------------------------------------------------------

func _process(_delta: float) -> void:
	if effect_running:
		return  # Prevent multiple respawn calls if one is already active

	# Check if player is inside and a valid respawn point is set,
	# or if the player presses the manual respawn key (R)
	if (entered and respawn_position != Vector2.ZERO) or Input.is_key_pressed(KEY_R):
		respawn_with_effect()

# ------------------------------------------------------------------------------
# RESPAWN SEQUENCE WITH TRANSITION EFFECT
# ------------------------------------------------------------------------------

func respawn_with_effect():
	effect_running = true  # Block further triggers

	var player = get_tree().current_scene.get_node("Player")  # Get the player node
	var blur_effect = $"../CanvasLayer/Respawn_Effect"  # Reference to the transition blur
	var blur_material := blur_effect.material as ShaderMaterial  # Shader material used for blur

	blur_effect.visible = true  # Show the blur overlay

	# Create tween to animate the shader effect
	var tween := get_tree().create_tween()

	respawn_timer()  # Start timer to actually teleport the player later

	# Animate the blur height to show a blur effect in and out
	tween.tween_property(blur_material, "shader_parameter/height", 1.0, 0.7)
	tween.tween_property(blur_material, "shader_parameter/height", -1.0, 0.7)

	# Delay to prevent input before respawn finishes
	await get_tree().create_timer(0.15).timeout
	player.input_enabled = false  # Temporarily disable player controls

	await tween.finished
	player.input_enabled = true  # Re-enable controls after animation

	blur_effect.visible = false  # Hide the blur overlay
	effect_running = false  # Allow future respawns

# ------------------------------------------------------------------------------
# ACTUAL TELEPORTATION (DELAYED BY A TIMER)
# ------------------------------------------------------------------------------

func respawn_timer():
	var player = get_tree().current_scene.get_node("Player")
	await get_tree().create_timer(0.5).timeout  # Delay actual teleport slightly for visual sync
	player.global_position = respawn_position  # Teleport the player to the designated point
