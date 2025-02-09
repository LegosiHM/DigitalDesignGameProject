extends Node2D

@export var detection_radius: float = 100.0 
var player = null
var rb2d: RigidBody2D
var dragging = false
var offset = Vector2.ZERO  

func _ready():
	rb2d = $RigidBody2D 

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body and body.name == "Player":
		player = body
		print("Player detected")

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body and body.name == "Player":
		player = null
		print("Player left the detection range")

func _process(_delta):
	if player:
		if Input.is_action_pressed("drag"): 
			if not dragging:
				offset = rb2d.position - player.position
			dragging = true
		else:
			dragging = false
		
		if dragging:
			rb2d.position = player.position + offset
			print("Box Position: ", rb2d.position)  
		else:
			pass
