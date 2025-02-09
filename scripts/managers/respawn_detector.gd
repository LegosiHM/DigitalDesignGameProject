extends Area2D

var entered = false
@export var respawn_position: Vector2

func _on_body_entered(body: PhysicsBody2D) -> void:
	entered = true

func _on_body_exited(body: PhysicsBody2D) -> void:
	entered = false

func _process(delta: float) -> void:
	if (entered and respawn_position) or (Input.is_key_pressed(KEY_R)):
		get_tree().current_scene.get_node("Player").global_position = respawn_position
		
