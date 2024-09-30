extends Sprite2D

var dragging = false
var of = Vector2(0, 0) 
var original_position = Vector2(0, 0)
var returning = false

@export var return_speed = 200.0
@export var return_multiplier = 1.0

func _ready() -> void:
	original_position = global_position

func _process(delta: float) -> void:
	if dragging:
		position = get_global_mouse_position() - of
		returning = false 
	elif returning:
		global_position = global_position.move_toward(original_position, return_speed * return_multiplier * delta)
		if global_position.distance_to(original_position) < 1.0:
			returning = false
			global_position = original_position 

func _on_button_button_down() -> void:
	dragging = true
	of = get_global_mouse_position() - global_position

func _on_button_button_up() -> void:
	dragging = false
	returning = true
