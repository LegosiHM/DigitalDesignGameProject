extends Area2D

@export var respawn_position: Vector2
var entered := false
var effect_running := false


func _on_body_entered(body: PhysicsBody2D) -> void:
	entered = true

func _on_body_exited(body: PhysicsBody2D) -> void:
	entered = false

func _process(delta: float) -> void:
	if effect_running:
		return

	if (entered and respawn_position != Vector2.ZERO) or Input.is_key_pressed(KEY_R):
		respawn_with_effect()

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
	await get_tree().create_timer(0.5).timeout
	player.global_position = respawn_position
