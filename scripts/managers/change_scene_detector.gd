extends Area2D

var entered = false
@export var my_scene: String

func _on_body_entered(body: PhysicsBody2D) -> void:
	entered = true

func _on_body_exited(body: PhysicsBody2D) -> void:
	entered = false

func _process(delta: float) -> void:
	if entered and my_scene:
		get_tree().change_scene_to_file(my_scene)
