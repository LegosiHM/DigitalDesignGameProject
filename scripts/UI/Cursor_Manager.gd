extends Node

var idle_cursor = preload("res://assets/UI/UI_Cursor_Hover_v03.png")
var click_cursor = preload("res://assets/UI/UI_Cursor_Dragging_v03.png")

func _ready():
	# Set initial cursor
	Input.set_custom_mouse_cursor(idle_cursor)
	set_process_input(true)

func _input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			Input.set_custom_mouse_cursor(click_cursor)
		else:
			Input.set_custom_mouse_cursor(idle_cursor)
