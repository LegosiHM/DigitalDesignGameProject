extends CanvasLayer  # This script controls screen transitions via a ColorRect shader effect

# ------------------------------------------------------------------------------
# NODE REFERENCES
# ------------------------------------------------------------------------------

# Reference to the screen transition ColorRect (which must use a shader)
@onready var transition_rect: ColorRect = get_node_or_null("../CanvasLayer/Scenes_Transition")

# ------------------------------------------------------------------------------
# SHADER FADE CONFIGURATION VALUES (Add these if adjustable via Inspector)
# ------------------------------------------------------------------------------

# Duration for fade-out and position reveal
const FADE_OUT_DURATION := 0.1
const REVEAL_POSITION_DURATION := 0.8

# Target shader values
const IN_OUT_START := 1.0  # Screen starts fully covered
const IN_OUT_END := 0.0    # Screen ends uncovered
const POSITION_START := -1.5  # Fully over the screen
const POSITION_END := 1.0     # Off-screen (revealed)

# ------------------------------------------------------------------------------
# READY: Initialize and trigger fade-out animation
# ------------------------------------------------------------------------------

func _ready():
	# If transition_rect or its shader material is missing, report error
	if transition_rect and transition_rect.material:
		# Set the initial shader state to cover the screen fully
		transition_rect.material.set_shader_parameter("in_out", IN_OUT_START)
		transition_rect.material.set_shader_parameter("position", POSITION_START)
		play_fade_out()  # Start fade-out animation
	else:
		push_error("ERROR: ColorRect or its material is missing!")

# ------------------------------------------------------------------------------
# PLAY FADE OUT: Animate screen transition from fully covered to revealed
# ------------------------------------------------------------------------------

func play_fade_out():
	var tween = create_tween()

	# Animate 'in_out' from 1.0 to 0.0 to start revealing screen
	tween.tween_property(
		transition_rect.material, "shader_parameter/in_out", 
		IN_OUT_END, FADE_OUT_DURATION
	).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)

	# Animate 'position' to slide transition effect off the screen
	tween.tween_property(
		transition_rect.material, "shader_parameter/position", 
		POSITION_END, REVEAL_POSITION_DURATION
	).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)

	await tween.finished  # Wait for animation to complete before ending function
