extends Node2D

@export var dialog_lines: Array[String] = []  
@export var dialog_position_Array: Array[Vector2] = []
#var dialog_position: Vector2 
@export var cooldown_time: float = 2.0  

@onready var area = $Area2D
@onready var cooldown_timer = Timer.new()  

var i = 0
var dialog_active = false
var can_interact = true  

@export var will_reveal_object = false
@export var reveal_panel: Node2D
@export var reveal_path: Area2D

func _ready():
	area.input_event.connect(_on_input_event)  
	add_child(cooldown_timer)  
	cooldown_timer.one_shot = true  
	cooldown_timer.timeout.connect(_reset_interaction)

func _process(delta):
	if visible:
		can_interact = true
		set_process(false)
	else:
		can_interact = false

func _on_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed:
		if !can_interact or dialog_active:  
			return

		_show_dialog()

func _show_dialog():
	dialog_active = true
	can_interact = false  
	DialogManager.start_dialog(dialog_position_Array, dialog_lines, self)

func _on_dialog_finished():
	cooldown_timer.start(cooldown_time)  
	dialog_active = false
	
	if will_reveal_object:
		if reveal_panel != null:
			reveal_panel.visible = true
			#print(reveal_panel.name)
		if reveal_path != null:
			reveal_path.visible = true
			#print(reveal_path.name)
		

func _reset_interaction():
	can_interact = true  
