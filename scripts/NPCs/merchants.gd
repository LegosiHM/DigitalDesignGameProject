extends Node2D

@export var dialog_lines: Array[String] = []

@export var dialog_position: Vector2 = Vector2(0, -50)  # Position of the dialog box

@onready var area = $Area2D

var dialog_active = false

func _ready():
	area.input_event.connect(_on_input_event)  # Detect mouse clicks

func _on_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed:
		if !dialog_active:
			_show_dialog()  # First click starts dialog
		else:
			DialogManager.advance_dialog()  # Clicking again advances dialog

func _show_dialog():
	dialog_active = true
	DialogManager.start_dialog(global_position + dialog_position, dialog_lines, self)

func close_dialog():
	dialog_active = false  # Reset state so the panel can be clicked again
