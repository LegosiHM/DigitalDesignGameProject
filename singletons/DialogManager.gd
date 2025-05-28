extends Node

# -------------------------------------
# DIALOG BOX SCENE REFERENCE
# -------------------------------------
@onready var text_box_scene = preload("res://Scenes/UI/TextBox.tscn")  
# This is the scene that will be instantiated each time a dialog box is needed.

# -------------------------------------
# DIALOG CONTENT STATE
# -------------------------------------
var dialog_lines: Array[String] = []  # Stores lines of dialog to show
var dialog_position_Array: Array[Vector2] = []  # Positions where each line should appear
var dialog_position: Vector2  # Current position of the dialog box
var current_line_index: int = 0  # Tracks the current line being shown

# -------------------------------------
# DIALOG SYSTEM STATE
# -------------------------------------
var text_box  # Instance of the dialog box currently shown
var is_dialog_active: bool = false  # True when dialog is running
var can_advance_line: bool = false  # True when text is fully displayed
var current_panel = null  # Optional reference to the panel that triggered this dialog (for callback)

# -------------------------------------
# start_dialog(): Begins a new dialog sequence
# -------------------------------------
func start_dialog(positions: Array[Vector2], lines: Array[String], panel = null):
	if is_dialog_active:
		return  # Prevent starting another dialog while one is active

	dialog_lines = lines
	dialog_position_Array = positions
	is_dialog_active = true
	current_line_index = 0  
	dialog_position = dialog_position_Array[current_line_index]
	current_panel = panel  # Optional: Store the panel that initiated the dialog

	_show_text_box()  # Start by showing the first text box

# -------------------------------------
# _show_text_box(): Instantiates and shows the dialog box
# -------------------------------------
func _show_text_box():
	if text_box:
		text_box.queue_free()  # Clean up old text box before showing a new one

	text_box = text_box_scene.instantiate()
	text_box.finished_displaying.connect(_on_text_box_finished_displaying)
	get_tree().root.add_child(text_box)

	text_box.position = dialog_position  # Position the text box

	# Smooth fade-in animation
	text_box.modulate.a = 0
	var tween = get_tree().create_tween()
	tween.tween_property(text_box, "modulate:a", 1.0, 0.3)

	text_box.display_text(dialog_lines[current_line_index])  # Start showing the first line
	can_advance_line = false  # Player can't skip until fully displayed

# -------------------------------------
# _on_text_box_finished_displaying(): Called when text finishes typing
# -------------------------------------
func _on_text_box_finished_displaying():
	can_advance_line = true

# -------------------------------------
# _unhandled_input(): Handles advancing dialog on input
# -------------------------------------
func _unhandled_input(event):
	if event.is_action_pressed("advance_dialog") and is_dialog_active:
		
		# Prevent advancing if text is still typing
		if not can_advance_line:
			if text_box.label.text != text_box.text:
				text_box.label.text = text_box.text  # Instantly reveal text
				text_box.timer.stop()  # Stop the typing delay
				text_box.finished_displaying.emit()  # Manually trigger completion
				can_advance_line = true
			return

		current_line_index += 1  # Move to next line

		# Dialog is done
		if current_line_index >= dialog_lines.size():
			close_dialog()
			return

		# Show next line at corresponding position
		dialog_position = dialog_position_Array[current_line_index]
		_show_text_box()
		can_advance_line = false

# -------------------------------------
# close_dialog(): Ends dialog and cleans up
# -------------------------------------
func close_dialog():
	if text_box:
		var tween = get_tree().create_tween()
		tween.tween_property(text_box, "modulate:a", 0.0, 0.3)  # Fade out
		tween.tween_callback(text_box.queue_free)
		text_box = null

	is_dialog_active = false
	current_line_index = 0

	# Call back to the panel that triggered dialog if needed
	if current_panel:
		current_panel._on_dialog_finished()
		current_panel = null
