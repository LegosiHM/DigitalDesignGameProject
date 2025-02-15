extends Area2D

@export var my_scene: String
@onready var transition_rect: ColorRect = get_node_or_null("../CanvasLayer/ColorRect")  # Safe node retrieval
var transitioning = false  # Prevent multiple triggers

func _ready():
	if transition_rect and transition_rect.material:
		transition_rect.material.set_shader_parameter("in_out", 0.0)  # Start hidden
		transition_rect.material.set_shader_parameter("position", 1.0)  # Start with no effect
	else:
		push_error("ERROR: ColorRect or its material is missing!")

func _on_body_entered(body: PhysicsBody2D) -> void:
	if transitioning or my_scene.is_empty():
		return
	transitioning = true
	start_scene_transition()

func start_scene_transition():
	if not transition_rect or not transition_rect.material:
		push_error("ERROR: Cannot animate transition, ColorRect or material is missing!")
		get_tree().change_scene_to_file(my_scene)  # Fallback to instant scene change
		return

	var tween = create_tween()
	tween.tween_property(
		transition_rect.material, "shader_parameter/in_out", 
		1.0, 0.1  # Fade in effect
	).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	
	tween.tween_property(
		transition_rect.material, "shader_parameter/position", 
		-1.5, 0.8  # Cover the whole screen
	).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	await tween.finished  # Wait for animation to complete

	get_tree().change_scene_to_file(my_scene)  # Change scene AFTER transition
