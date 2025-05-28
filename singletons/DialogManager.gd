extends Node

# ------------------------------------------------------------------------------
# DIALOG BOX SCENE REFERENCE
# ------------------------------------------------------------------------------

@onready var text_box_scene = preload("res://Scenes/UI/TextBox.tscn")
# Preloads the dialog box scene to be instantiated on demand.

# ------------------------------------------------------------------------------
# DIALOG CONTENT STATE
# ------------------------------------------------------------------------------

var dialog_lines: Array[String] = []            # List of dialog strings to display
var dialog_position_Array: Array[Vector2] = []  # Corresponding positions for each dialog line
var dialog_position: Vector2                    # Current dialog box position
var current_line_index: int = 0                 # Tracks which dialog line is currently shown

# ------------------------------------------------------------------------------
# DIALOG SYSTEM STATE
# ------------------------------------------------------------------------------

var text_box: Node = null             # The current instance of the dialog box
var is_dialog_active: bool = false    # Is a dialog session currently active?
var can_advance_line: bool = false    # True when the player can proceed to the next line
var current_panel = null              # Optional reference to panel that triggered the dialog

# ------------------------------------------------------------------------------
# DIALOG ENTRY POINT
# ------------------------------------------------------------------------------

# Starts a dialog sequence using line text and position arrays
func start_dialog(positions: Array[Vector2], lines: Array[String], panel = null):
	if is_dialog_active:
		return  # Prevent multiple dialogs at once

	dialog_lines = lines
	dialog_position_Array = positions
	current_line_index = 0
	dialog_position = dialog_position_Array[current_line_index]
	current_panel = panel  # Store panel reference if passed
	is_dialog_active = true

	_show_text_box()

# ------------------------------------------------------------------------------
# TEXT BOX INSTANTIATION AND DISPLAY
# ------------------------------------------------------------------------------

# Spawns and shows the dialog box with fade-in effect
func _show_text_box():
	if text_box:
		text_box.queue_free()  # Remove any previous box before creating a new one

	text_box = text_box_scene.instantiate()
	text_box.finished_displaying.connect(_on_text_box_finished_displaying)

	# Attach to current scene's root
	if get_tree().current_scene:
		get_tree().current_scene.add_child(text_box)

	# Position the dialog box
	text_box.position = dialog_position

	# Fade in animation
	text_box.modulate.a = 0
	var tween = get_tree().create_tween()
	tween.tween_property(text_box, "modulate:a", 1.0, 0.3)

	# Start typing the first line
	text_box.display_text(dialog_lines[current_line_index])
	can_advance_line = false

# ------------------------------------------------------------------------------
# DISPLAY COMPLETION HANDLER
# ------------------------------------------------------------------------------

# Called when the text box has fully typed out its message
func _on_text_box_finished_displaying():
	can_advance_line = true

# ------------------------------------------------------------------------------
# PLAYER INPUT TO ADVANCE DIALOG
# ------------------------------------------------------------------------------

# Handles input when player tries to move to next dialog line
func _unhandled_input(event):
	if event.is_action_pressed("advance_dialog") and is_dialog_active:

		# If the text isn't fully typed yet, finish it instantly
		if not can_advance_line:
			if text_box.label.text != text_box.text:
				text_box.label.text = text_box.text  # Display full text instantly
				text_box.timer.stop()               # Cancel any further delay
				text_box.finished_displaying.emit() # Manually complete
				can_advance_line = true
			return

		# Go to the next line
		current_line_index += 1

		# If we're done with all lines, clean up
		if current_line_index >= dialog_lines.size():
			close_dialog()
			return

		# Show the next line at its assigned position
		dialog_position = dialog_position_Array[current_line_index]
		_show_text_box()
		can_advance_line = false

# ------------------------------------------------------------------------------
# CLEANUP AND EXIT
# ------------------------------------------------------------------------------

# Ends the dialog session and optionally notifies the triggering panel
func close_dialog():
	if text_box:
		var tween = get_tree().create_tween()
		tween.tween_property(text_box, "modulate:a", 0.0, 0.3)  # Fade out animation
		tween.tween_callback(text_box.queue_free)
		text_box = null

	is_dialog_active = false
	current_line_index = 0

	# Notify the panel that dialog finished
	if current_panel:
		current_panel._on_dialog_finished()
		current_panel = null
