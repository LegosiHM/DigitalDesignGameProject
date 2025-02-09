extends Node

@onready var text_box_scene = preload("res://scenes/UI/Text_Box.tscn")  # Updated scene reference

var dialog_lines: Array[String] = []
var current_line_index = 0

var text_box
var text_box_position: Vector2
var is_dialog_active = false
var can_advance_line = false

func start_dialog(position: Vector2, lines: Array[String], panel = null):
	if is_dialog_active:
		return

	dialog_lines = lines
	text_box_position = position  # Store position for every dialog line
	is_dialog_active = true
	current_line_index = 0  # Reset dialog to the first line

	_show_text_box()  # Show the first dialog line **with animation**

func _show_text_box():
	if text_box:
		text_box.queue_free()  # Remove the previous dialog before creating a new one

	text_box = text_box_scene.instantiate()
	text_box.finished_displaying.connect(_on_text_box_finished_displaying)
	get_tree().root.add_child(text_box)

	# Ensure dialog box always appears in the correct position
	text_box.global_position = text_box_position  

	# Smooth fade-in animation for the dialog
	text_box.modulate.a = 0
	var tween = get_tree().create_tween()
	tween.tween_property(text_box, "modulate:a", 1.0, 0.3)  # Fade-in effect over 0.3 seconds

	text_box.display_text(dialog_lines[current_line_index])  # Display text for the current line
	can_advance_line = false

func _on_text_box_finished_displaying():
	can_advance_line = true  # Allow the player to advance to the next line

func _unhandled_input(event):
	if event.is_action_pressed("advance_dialog") && is_dialog_active:
		if !can_advance_line:
			text_box.label.text = text_box.text  # Instantly show full text if still animating
			text_box.finished_displaying.emit()
			return  

		current_line_index += 1  # Move to next line

		if current_line_index >= dialog_lines.size():
			close_dialog()
			return

		# Ensure the next line appears in the correct position
		text_box_position = text_box.global_position  

		_show_text_box()  # Display the next line **at the correct position**
		can_advance_line = false

func close_dialog():
	if text_box:
		var tween = get_tree().create_tween()
		tween.tween_property(text_box, "modulate:a", 0.0, 0.3)  # Smooth fade-out animation
		tween.tween_callback(text_box.queue_free)  # Remove text box after fading out
		text_box = null

	is_dialog_active = false
	current_line_index = 0  # Reset for the next dialog session

func advance_dialog():
	if !is_dialog_active:
		return
	
	if !can_advance_line:
		text_box.label.text = text_box.text  # Instantly reveal full text
		text_box.finished_displaying.emit()
		return  
	
	current_line_index += 1  # Move to next line
	
	if current_line_index >= dialog_lines.size():
		close_dialog()
		return
		
	# Ensure the next line appears in the correct position
	text_box_position = text_box.global_position  
	
	_show_text_box()  # Display the next line **at the correct position**
	can_advance_line = false
