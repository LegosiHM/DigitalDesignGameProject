extends Area2D

@onready var player = get_tree().current_scene.get_node("Player")
var dragging = false
var collide = false
var offset = Vector2(0, 0)
var original_position = Vector2(0, 0)
var returning = false
var return_speed = 150.0
var illegalDragging_speed = 30.0
var normalDragging_speed = 1000.0

var velocity = Vector2.ZERO

func _ready() -> void:
	original_position = global_position


func _process(delta: float) -> void:
	check_overlap_area()
	
	if dragging:
		var energy_needed = 2 if collide else 1
		if not player.consume_energy(energy_needed):  
			dragging = false
			returning = true  # If no energy left, return panel
		else:
			var new_position = get_global_mouse_position() - offset
			velocity = new_position - global_position
			global_position = global_position.move_toward(new_position, (illegalDragging_speed if collide else normalDragging_speed) * delta)
	
	elif returning:
		global_position = global_position.move_toward(original_position, return_speed * delta)
		if global_position.distance_to(original_position) < 1.0:
			returning = false
			global_position = original_position

func _on_button_button_down() -> void:
	if player.current_energy < player.threshold_energy:
		return  # Prevent dragging if energy is below the threshold

	dragging = true
	returning = false
	offset = get_global_mouse_position() - global_position
	player.is_dragging_panel = true

func _on_button_button_up() -> void:
	dragging = false
	returning = true
	player.is_dragging_panel = false

func check_overlap_area():
	collide = has_overlapping_areas()
