extends Sprite2D

var dragging = false
var of = Vector2(0, 0)
var original_position = Vector2(0, 0)
var returning = false
var return_speed = 200.0
@export var player_node_path: NodePath  
@onready var player = get_node(player_node_path)
var velocity = Vector2.ZERO
var is_player_on_platform = false

signal player_on_platform(on_platform: bool)  

func _ready() -> void:
	original_position = global_position

func _process(delta: float) -> void:
	if dragging:
		var new_position = get_global_mouse_position() - of
		velocity = new_position - global_position
		global_position = new_position

		if check_player_on_platform(): 
			player.global_position += velocity 

	elif returning:
		global_position = global_position.move_toward(original_position, return_speed * delta)
		if global_position.distance_to(original_position) < 1.0:
			returning = false
			global_position = original_position

	is_player_on_platform = check_player_on_platform()

func _on_button_button_down() -> void:
	dragging = true
	returning = false
	of = get_global_mouse_position() - global_position

func _on_button_button_up() -> void:
	dragging = false
	returning = true
	

func check_player_on_platform() -> bool:
	var on_platform = false
	if player and player.is_on_floor():
		var floor_normal = player.get_floor_normal()
		if floor_normal == Vector2.UP:  
			var platform_rect = get_rect()
			if platform_rect.has_point(player.global_position):
				on_platform = true
	emit_signal("player_on_platform", on_platform)
	return on_platform
