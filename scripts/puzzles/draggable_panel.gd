extends Area2D

@onready var player = get_tree().current_scene.get_node("Player")
var dragging = false
var collide = false
var offset = Vector2(0, 0)
var original_position = Vector2(0, 0)
var returning = false
@export var return_speed = 150.0
@export var illegalDragging_speed = 30.0
@export var normalDragging_speed = 1000.0
@export var energyConsumption = 1
#if untouchable panel
@export var untouchable = false
var respawn_manager 
var respawn_position
var player_position

#if stuck on Collider
@export var stuckOnCollider = false

var velocity = Vector2.ZERO

var effect_running := false

func _ready() -> void:
	original_position = global_position
	respawn_manager = get_tree().current_scene.get_node("RespawnDetector")
	respawn_position = respawn_manager.respawn_position #sometimes there is a bug here. Might need some fix later

func _process(delta: float) -> void:
	
	check_overlap_area()
	player_position = get_tree().current_scene.get_node("Player").global_position
	
	#print(overlap_area)
	if untouchable:
		#if (collide and global_position.distance_to(player_position) < 150):
		if(collide): #need to be fix to check if collide with just player's collision
			respawn_with_effect()
	
	if dragging:
		var energy_needed = 2*energyConsumption if collide else energyConsumption
		if not player.consume_energy(energy_needed):  
			dragging = false
			returning = true  # If no energy left, return panel
		else:
			var new_position = get_global_mouse_position() - offset
			velocity = new_position - global_position
			global_position = global_position.move_toward(new_position, (illegalDragging_speed if collide else normalDragging_speed) * delta)
	
	elif returning:
		if(stuckOnCollider):
			if(collide):
				global_position = global_position.move_toward(original_position, return_speed * delta)
				global_position = global_position.move_toward(original_position, -return_speed*delta)
			else:
				global_position = global_position.move_toward(original_position, return_speed * delta)
		else:
			global_position = global_position.move_toward(original_position, return_speed * delta)
		
		if global_position.distance_to(original_position) < 1.0:
			returning = false
			global_position = original_position
			

func _on_button_button_down() -> void:
	if player.current_energy < player.threshold_energy:
		return  # Prevent dragging if energy is below the threshold

	dragging = true
	returning = false
	offset = get_global_mouse_position() - global_position
	player.is_dragging_panel = true

func _on_button_button_up() -> void:
	dragging = false
	returning = true
	player.is_dragging_panel = false

func check_overlap_area():
	collide = has_overlapping_areas()
	
func respawn_with_effect():
	effect_running = true

	var player = get_tree().current_scene.get_node("Player")
	var blur_effect = $"../CanvasLayer/Respawn_Effect"
	var material := blur_effect.material as ShaderMaterial

	blur_effect.visible = true

	var tween := get_tree().create_tween()
	respawn_timer()
	tween.tween_property(material, "shader_parameter/height", 1.0, 0.7)
	tween.tween_property(material, "shader_parameter/height", -1.0, 0.7)
	await tween.finished

	blur_effect.visible = false

	effect_running = false
	
func respawn_timer():
	var player = get_tree().current_scene.get_node("Player")
	await get_tree().create_timer(0.1).timeout
	player.global_position = respawn_position
	
