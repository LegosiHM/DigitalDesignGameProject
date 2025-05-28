extends Node

# -------------------------------------
# CURSOR TEXTURES
# -------------------------------------
# Custom cursor texture shown during normal hover
var idle_cursor = preload("res://assets/UI/UI_Cursor_Hover_v03.png")

# Custom cursor texture shown when mouse button is held
var click_cursor = preload("res://assets/UI/UI_Cursor_Dragging_v03.png")

# -------------------------------------
# _ready(): Setup when node enters the scene tree
# -------------------------------------
func _ready():
	# Set the initial mouse cursor to the idle version
	Input.set_custom_mouse_cursor(idle_cursor)

	# Enable processing of input events (so _input() is called)
	set_process_input(true)

# -------------------------------------
# _input(event): Change cursor based on mouse button press
# -------------------------------------
func _input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			# Change cursor to click state when mouse button is pressed
			Input.set_custom_mouse_cursor(click_cursor)
		else:
			# Revert back to idle cursor when button is released
			Input.set_custom_mouse_cursor(idle_cursor)
