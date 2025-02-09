extends Node

@onready var text_box_scene = preload("res://scenes/UI/Text_Box.tscn")

var dialog_lines: Array[String] = []
var current_line_index = 0
var text_box
var text_box_position: Vector2
var is_dialog_active = false
var can_advance_line = false
var current_panel = null  

var panel_sequence = []  # ✅ Ordered sequence of panels
var current_panel_index = 0  # ✅ Track the current panel in the order

func register_panel_sequence(sequence: Array):
	panel_sequence = sequence  # ✅ Store custom order
	current_panel_index = 0
	
	print("Registered panel sequence: ", panel_sequence)
	
	if panel_sequence.size() > 0:
		print("First panel enabled: ", panel_sequence[0].name)
		panel_sequence[0].enable_interaction()  # ✅ Enable only the first panel

func start_dialog(position: Vector2, lines: Array[String], panel = null):
	print("Starting dialog from panel:", panel.name)  # ✅ Debugging to confirm which panel is sending the dialog
	
	if is_dialog_active:
		print("Dialog already active, ignoring new request")  # ✅ Check if dialog is blocked
		return
	
	if dialog_lines != lines:
		dialog_lines = lines
		current_line_index = 0  
	
	text_box_position = position
	is_dialog_active = true
	current_panel = panel  
	
	_show_text_box()


func _show_text_box():
	if text_box:
		text_box.queue_free()
	
	if current_line_index >= dialog_lines.size():
		close_dialog()
		return
	
	text_box = text_box_scene.instantiate()
	text_box.finished_displaying.connect(_on_text_box_finished_displaying)
	get_tree().root.add_child(text_box)

	text_box.global_position = text_box_position  

	text_box.modulate.a = 0
	var tween = get_tree().create_tween()
	tween.tween_property(text_box, "modulate:a", 1.0, 0.3)  

	text_box.display_text(dialog_lines[current_line_index])
	can_advance_line = false

func _on_text_box_finished_displaying():
	can_advance_line = true  

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

	if current_panel_index < panel_sequence.size() - 1:
		current_panel_index += 1
		panel_sequence[current_panel_index].enable_interaction()

	if current_panel:
		current_panel._on_dialog_finished()
		current_panel = null  
