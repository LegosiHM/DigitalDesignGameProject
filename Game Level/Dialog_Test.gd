extends Sprite2D

@onready var dialog_manager = get_node("/root/DialogManager")

func _input(event):
	if event.is_action_pressed("ui_accept"):  # Default action key is Enter/Space/Z
		_start_dialog()

func _start_dialog():
	var position = global_position + Vector2(0, -50)  # Position above the sprite
	var lines: Array[String] = [  # Explicitly define as an Array of Strings
		"Hello! This is a test dialog.",
		"Press [Enter] to continue...",
		"This is the last line!"
	]
	dialog_manager.start_dialog(position, lines)  # Pass correctly typed Array
