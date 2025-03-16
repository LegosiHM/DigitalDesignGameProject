extends Node

@onready var text_box_scene = preload("res://scenes/UI/TextBox.tscn")  # Make sure path is correct

var dialog_lines: Array[String] = []
var current_line_index = 0

var text_box
var text_box_position: Vector2
var is_dialog_active = false
var can_advance_line = false
var current_panel = null  # Stores the panel that triggered the dialog

func start_dialog(position: Vector2, lines: Array[String], panel = null):
	if is_dialog_active:
		return

	dialog_lines = lines
	text_box_position = position  
	is_dialog_active = true
	current_line_index = 0  
	current_panel = panel  # Store the interacting panel

	_show_text_box()  

func _show_text_box():
	if text_box:
		text_box.queue_free()  

	text_box = text_box_scene.instantiate()
	text_box.finished_displaying.connect(_on_text_box_finished_displaying)
	get_tree().root.add_child(text_box)

	text_box.global_position = text_box_position  

	text_box.modulate.a = 0
	var tween = get_tree().create_tween()
	tween.tween_property(text_box, "modulate:a", 1.0, 0.3)  # Smooth fade-in

	text_box.display_text(dialog_lines[current_line_index])  
	can_advance_line = false  

func _on_text_box_finished_displaying():
	can_advance_line = true  # Now player can click to advance

func _unhandled_input(event):
	if event.is_action_pressed("advance_dialog") && is_dialog_active:
		if !can_advance_line:  
			if text_box.label.text != text_box.text:
				text_box.label.text = text_box.text  
				text_box.timer.stop()  
				text_box.finished_displaying.emit()  
				can_advance_line = true  
			return  

		current_line_index += 1  

		if current_line_index >= dialog_lines.size():
			close_dialog()
			return

		_show_text_box()
		can_advance_line = false  

func close_dialog():
	if text_box:
		var tween = get_tree().create_tween()
		tween.tween_property(text_box, "modulate:a", 0.0, 0.3)  
		tween.tween_callback(text_box.queue_free)  
		text_box = null

	is_dialog_active = false
	current_line_index = 0  

	if current_panel:
		current_panel._on_dialog_finished()  
		current_panel = null  
