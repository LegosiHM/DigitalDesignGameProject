extends Sprite2D

var dragging = false
var of = Vector2(0, 0) ## Offset
var original_position = Vector2(0, 0)
var returning = false
var return_speed = 200.0

# Called when the node is ready
func _ready() -> void:
	original_position = global_position

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if dragging:
		position = get_global_mouse_position() - of
	elif returning:
		# Move the object back to its original position smoothly
		global_position = global_position.move_toward(original_position, return_speed * delta)
		if global_position.distance_to(original_position) < 1.0:
			returning = false
			global_position = original_position  # Snap to original position

func _on_button_button_down() -> void:
	dragging = true
	returning = false  # Stop returning if dragging starts again
	of = get_global_mouse_position() - global_position

func _on_button_button_up() -> void:
	dragging = false
	returning = true  # Start returning to original position
