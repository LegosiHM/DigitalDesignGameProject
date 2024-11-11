extends Area2D

@export var drag_range = 200.0
var player_in_range = false
var dragging = false
var player
var original_position
var offset = Vector2.ZERO

func _ready():
	original_position = position
	var shape = $CollisionShape2D.shape
	if shape is RectangleShape2D:
		shape.extents = Vector2(drag_range, drag_range)

func _on_Area2D_body_entered(body):
	if body.name == "Player":  
		player_in_range = true
		player = body

func _on_Area2D_body_exited(body):
	if body.name == "Player":
		player_in_range = false

func _process(delta):
	if player_in_range and Input.is_action_pressed("drag"):
		if not dragging: 
			offset = position - player.global_position
		dragging = true
	else:
		dragging = false

	if dragging:
		position = player.global_position + offset

	_keep_within_boundaries()

func _keep_within_boundaries():
	pass
