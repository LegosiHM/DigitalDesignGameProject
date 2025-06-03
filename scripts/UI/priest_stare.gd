extends Node2D

@export var player_node: Node2D
@onready var eyes = $StoryPanelBazaarPriestGlaringV_03Eye

const EYE_X_MIN := 280.0
const EYE_X_MAX := 390.0

const PLAYER_X_MIN := 0.0
const PLAYER_X_MAX := 1080.0

var eye_x_smooth := EYE_X_MIN  # current smoothed position
var eye_lerp_speed := 4.0      # smaller = slower smoothing (try 2.0–6.0)

func _process(delta):
	if player_node == null:
		return

	var px = player_node.global_position.x
	var t = clamp((px - PLAYER_X_MIN) / float(PLAYER_X_MAX - PLAYER_X_MIN), 0.0, 1.0)
	var target_eye_x = lerp(EYE_X_MIN, EYE_X_MAX, t)

	# Smoothly move current eye position toward target
	eye_x_smooth = lerp(eye_x_smooth, target_eye_x, delta * eye_lerp_speed)

	# Apply smoothed position
	eyes.position.x = eye_x_smooth
