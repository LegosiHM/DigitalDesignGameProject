extends Area2D

var dragging = false
var collide = false
var of = Vector2(0, 0)
var original_position = Vector2(0, 0)
var returning = false
var return_speed = 200.0
var illegalDragging_speed = 50.0
var normalDragging_speed = 700.0

var maxEnergy = 100
var thresholdEnergy = 0.5 * maxEnergy
var currentEnergy = maxEnergy
var restoreEnergy = true

@export var player_node_path: NodePath  
@onready var player = get_node(player_node_path)
var velocity = Vector2.ZERO
var is_player_on_platform = false

signal player_on_platform(on_platform: bool)  

func _ready() -> void:
	original_position = global_position

func _process(delta: float) -> void:
	check_overlap_area()
	
	if restoreEnergy == true && currentEnergy < thresholdEnergy:
		#print("cant drag")
		dragging = false
		returning = true
		
	if dragging:
		restoreEnergy = false
		if currentEnergy >= 0:
			currentEnergy -= 1
			var new_position = get_global_mouse_position() - of
			velocity = new_position - global_position
			#print(currentEnergy)
			if currentEnergy <=0:
				dragging = false
			if collide == true:
				global_position = global_position.move_toward(new_position, illegalDragging_speed * delta)
			elif collide == false:
				global_position = global_position.move_toward(new_position, normalDragging_speed * delta)

	#if check_player_on_platform(): 
		#player.global_position += velocity 

	elif returning:
		restoreEnergy = true
			
		global_position = global_position.move_toward(original_position, return_speed * delta)
		if global_position.distance_to(original_position) < 1.0:
			returning = false
			global_position = original_position

	if currentEnergy <= 0:
			returning = true
			
	
		
	if restoreEnergy == true:
		if currentEnergy <= maxEnergy:
			currentEnergy += 1
			#print(currentEnergy)
	#is_player_on_platform = check_player_on_platform()

func _on_button_button_down() -> void:
	dragging = true
	returning = false
	of = get_global_mouse_position() - global_position

func _on_button_button_up() -> void:
	dragging = false
	returning = true


#func check_player_on_platform() -> bool:
	#var on_platform = false
	#if player and player.is_on_floor():
		#var floor_normal = player.get_floor_normal()
		#
		#if floor_normal == Vector2.UP:  
			#var platform_rect = get_rect()
			#if platform_rect.has_point(player.global_position):
				#on_platform = true
	#emit_signal("player_on_platform", on_platform)
	#return on_platform
	
func check_overlap_area():
		if has_overlapping_areas():
			collide = true
			#print(collide)
		else:
			collide = false 
			#print(collide)
