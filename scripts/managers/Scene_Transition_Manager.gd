extends CanvasLayer  # Now correctly extends CanvasLayer

@onready var transition_rect: ColorRect = get_node_or_null("../CanvasLayer/ColorRect")  # Ensure this exists

func _ready():
	if transition_rect and transition_rect.material:
		transition_rect.material.set_shader_parameter("in_out", 1.0)  # Start fully covered
		transition_rect.material.set_shader_parameter("position", -1.5)  # Fully covered
		play_fade_out()
	else:
		push_error("ERROR: ColorRect or its material is missing!")

func play_fade_out():
	var tween = create_tween()
	tween.tween_property(
		transition_rect.material, "shader_parameter/in_out", 
		0.0, 0.1  # Fade out effect
	).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	
	tween.tween_property(
		transition_rect.material, "shader_parameter/position", 
		1.0, 0.8  # Reveal the screen
	).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)

	await tween.finished
