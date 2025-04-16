extends Area2D

@export var my_scene: String
@onready var transition_rect: ColorRect = get_node_or_null("../CanvasLayer/Scenes_Transition")  # Safe node retrieval
@export var disable_on_default = false
@export var portal_visual: ColorRect
var transitioning = false  # A flag to prevent multiple scene transitions from happening at the same time.

func _ready():
	if disable_on_default == true:
		visible = false
		portal_visual.visible = false
		print("cant see warp")
	if transition_rect and transition_rect.material:
		 # If transition_rect and its material exist, set shader parameters to hide the transition effect.
		transition_rect.material.set_shader_parameter("in_out", 0.0)  # Makes sure the screen starts with no effect.
		transition_rect.material.set_shader_parameter("position", 1.0)  # Puts the effect off-screen.
	else:
		push_error("ERROR: ColorRect or its material is missing!")
		
func _process(delta):
	if visible == true:
		disable_on_default = false
		if portal_visual != null:
			portal_visual.visible = true
		
# This function is triggered when a PhysicsBody2D (like a player) enters the Area2D.
func _on_body_entered(body: PhysicsBody2D) -> void:
	if transitioning or my_scene.is_empty() or disable_on_default:
		return  # If a transition is already happening or the scene name is empty, do nothing.
	transitioning = true # Set the flag to true to prevent re-entering.
	start_scene_transition() # Call the function to start the transition effect.

# Function to start the scene transition animation.
func start_scene_transition():
	if not transition_rect or not transition_rect.material:
		push_error("ERROR: Cannot animate transition, ColorRect or material is missing!")
		get_tree().change_scene_to_file(my_scene)  # Fallback to instant scene change
		return

	var tween = create_tween() # Create a tween (an animation tool) to animate properties
	
	# Fade in effect (in_out shader parameter moves from 0.0 to 1.0 over 0.1 seconds).
	tween.tween_property(
		transition_rect.material, "shader_parameter/in_out", 
		1.0, 0.1  # Fade in effect
	).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	
	# Moves the shader effect to cover the whole screen over 0.5 seconds.
	tween.tween_property(
		transition_rect.material, "shader_parameter/position", 
		-1.5, 0.5  # Cover the whole screen
	).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	await tween.finished  # Waits until the animation is finished before changing the scene.

	get_tree().change_scene_to_file(my_scene)  # Change scene AFTER transition
		
