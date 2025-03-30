extends Area2D

var entered = false
@export var respawn_position: Vector2

func _on_body_entered(body: PhysicsBody2D) -> void:
	entered = true

func _on_body_exited(body: PhysicsBody2D) -> void:
	entered = false

func _process(delta: float) -> void:
	if (entered and respawn_position) or (Input.is_key_pressed(KEY_R)):
		var scene = get_tree().current_scene
		var blur_effect = $"../CanvasLayer/RespawnEffect"
		var material := blur_effect.material as ShaderMaterial

		blur_effect.visible = true

		var tween := get_tree().create_tween()
		tween.tween_property(material, "shader_parameter/blur_strength", 10.0, 0.2)
		tween.tween_property(material, "shader_parameter/blur_radius", 32.0, 0.3)
		tween.tween_property(material, "shader_parameter/blur_radius", 8.0, 0.3)
		tween.tween_property(material, "shader_parameter/blur_strength", 0.0, 0.2)


		await tween.finished
		var player = get_tree().current_scene.get_node("Player")
		blur_effect.visible = false
		get_tree().current_scene.get_node("Player").global_position = respawn_position
		player.state = player.IDLE
		
