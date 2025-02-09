extends Node2D

@export var dialog_lines: Array[String] = []  
@export var dialog_position: Vector2 = Vector2(0, -50)  
@export var cooldown_time: float = 1.0  

@onready var area = $Area2D
@onready var cooldown_timer = Timer.new()  

var can_interact = false  

func _ready():
	area.input_event.connect(_on_input_event)
	add_child(cooldown_timer)
	cooldown_timer.one_shot = true
	cooldown_timer.timeout.connect(_reset_interaction)

	await get_tree().process_frame  
	if DialogManager.panel_sequence.size() > 0 and self in DialogManager.panel_sequence:
		can_interact = true  

func _on_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed:
		print(name + " was clicked!")  # ✅ Debugging to confirm clicks are detected
		if can_interact:
			_show_dialog()
			DialogManager.close_dialog()
		else:
			print(name + " is NOT interactable!")  # ✅ Check if `can_interact` is still false


func _show_dialog():
	print(name + " is showing dialog!")  # ✅ Debugging to confirm dialog starts
	can_interact = false  
	DialogManager.start_dialog(global_position + dialog_position, dialog_lines, self)


# ✅ ADD THIS FUNCTION TO AVOID THE ERROR
func _on_dialog_finished():
	cooldown_timer.start(cooldown_time)  # ✅ Start cooldown before re-enabling interaction

func enable_interaction():
	print(name + " is now interactable")
	can_interact = true  

func _reset_interaction():
	can_interact = true  
