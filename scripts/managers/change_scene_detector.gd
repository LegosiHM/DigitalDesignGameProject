extends Area2D

# ------------------------------------------------------------------------------
# EXPORT SETTINGS (Set in Inspector)
# ------------------------------------------------------------------------------

@export var my_scene: String  # File path to the target scene to load
@export var disable_on_default := false  # If true, disables this portal and hides it
@export var portal_visual: ColorRect  # Optional visual indicator for the portal

# ------------------------------------------------------------------------------
# NODE REFERENCES
# ------------------------------------------------------------------------------

@onready var transition_rect: ColorRect = get_node_or_null("../CanvasLayer/Scenes_Transition")
# This references the screen-wide ColorRect used to animate shader-based screen transitions.

# ------------------------------------------------------------------------------
# STATE VARIABLES
# ------------------------------------------------------------------------------

var transitioning := false  # Prevents multiple transitions at the same time

# ------------------------------------------------------------------------------
# READY: Initial setup and optional deactivation
# ------------------------------------------------------------------------------

func _ready():
	if disable_on_default:
		visible = false
		if portal_visual:
			portal_visual.visible = false
		print("cant see warp")
	
	if transition_rect and transition_rect.material:
		# Ensure screen starts without visual effect from the shader
		transition_rect.material.set_shader_parameter("in_out", 0.0)
		transition_rect.material.set_shader_parameter("position", 1.0)  # Off-screen
	else:
		push_error("ERROR: ColorRect or its material is missing!")

# ------------------------------------------------------------------------------
# PROCESS: Portal re-activation for visual
# ------------------------------------------------------------------------------

func _process(_delta):
	if visible:
		disable_on_default = false  # Resets flag to allow reuse
		if portal_visual:
			portal_visual.visible = true  # Show portal visual if assigned

	# TEMP: Manual test trigger
	if Input.is_key_pressed(KEY_P):
		start_scene_transition()

# ------------------------------------------------------------------------------
# PHYSICS ENTER: Start transition if a valid body enters
# ------------------------------------------------------------------------------

func _on_body_entered(_body: PhysicsBody2D) -> void:
	if transitioning or my_scene.is_empty() or disable_on_default:
		return  # Abort if already transitioning, no scene set, or disabled

	transitioning = true
	start_scene_transition()

# ------------------------------------------------------------------------------
# SCENE TRANSITION FUNCTION (Animated)
# ------------------------------------------------------------------------------

func start_scene_transition():
	if not transition_rect or not transition_rect.material:
		push_error("ERROR: Cannot animate transition, ColorRect or material is missing!")
		get_tree().change_scene_to_file(my_scene)  # Fallback to instant switch
		return

	var tween = create_tween()

	# Fade in effect using custom shader (fade 0 → 1)
	tween.tween_property(
		transition_rect.material, "shader_parameter/in_out", 
		1.0, 0.1
	).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)

	# Slide effect: moves shader to cover screen (1.0 → -1.5)
	tween.tween_property(
		transition_rect.material, "shader_parameter/position", 
		-1.5, 0.5
	).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)

	await tween.finished  # Wait for animation before changing scenes
	get_tree().change_scene_to_file(my_scene)

# ------------------------------------------------------------------------------
# BODY EXITED (Optional Future Use)
# ------------------------------------------------------------------------------

func _on_body_exited(_body: Node2D) -> void:
	pass  # Can be used later to trigger visual or state changes
