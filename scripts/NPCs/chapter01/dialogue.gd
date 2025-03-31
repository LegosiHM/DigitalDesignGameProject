extends Node2D

@export var dialog_lines: Array[String] = []  
@export var dialog_position: Vector2 = Vector2(0, -50)  
@export var cooldown_time: float = 2.0  

@onready var area = $Area2D
@onready var cooldown_timer = Timer.new()  

var dialog_active = false
var can_interact = true  

func _ready():
	area.input_event.connect(_on_input_event)  
	add_child(cooldown_timer)  
	cooldown_timer.one_shot = true  
	cooldown_timer.timeout.connect(_reset_interaction)  

func _on_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed:
		if !can_interact or dialog_active:  
			return

		_show_dialog()

func _show_dialog():
	dialog_active = true
	can_interact = false  
	DialogManager.start_dialog(global_position + dialog_position, dialog_lines, self)

func _on_dialog_finished():
	cooldown_timer.start(cooldown_time)  
	dialog_active = false  

func _reset_interaction():
	can_interact = true  
