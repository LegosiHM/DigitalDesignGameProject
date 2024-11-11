extends Area2D

@export var drag_range: float = 200.0  
var player_in_range = false          
var dragging = false                  
var offset = Vector2.ZERO              

var player 

func _ready():
	player = get_tree().get_root().find_node("Player", true, false)
	if player == null:
		push_error("Player node not found in the scene tree.")

func _process(delta):
	if player == null:
		return

	var distance_to_player = position.distance_to(player.global_position)

	if distance_to_player <= drag_range:
		if not player_in_range:
			print("Player entered range")
			player_in_range = true
	else:
		if player_in_range:
			print("Player exited range")
			player_in_range = false
			dragging = false  

	if player_in_range and Input.is_action_pressed("drag"):
		if not dragging:
			offset = position - player.global_position
			dragging = true
	elif not Input.is_action_pressed("drag"):
		dragging = false

	if dragging:
		position = player.global_position + offset
