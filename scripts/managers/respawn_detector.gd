extends Area2D

@export var respawn_position: Vector2
var effect_running := false
var entered := false

func _on_body_entered(body: PhysicsBody2D) -> void:
	entered = true

func _on_body_exited(body: PhysicsBody2D) -> void:
	entered = false

func _process(delta: float) -> void:
	var player = get_tree().current_scene.get_node("Player")
	if effect_running:
		return

	if (entered and respawn_position) or (Input.is_key_pressed(KEY_R)):
		respawn_with_effect()
		
func respawn_with_effect():
	effect_running = true

	var blur_effect = $"../CanvasLayer/RespawnEffect"
	var material := blur_effect.material as ShaderMaterial

	blur_effect.visible = true
	
	respawn_timer()
	
	var tween := get_tree().create_tween()
	tween.tween_property(material, "shader_parameter/height", 1.0, 1.0)
	tween.tween_property(material, "shader_parameter/height", -1.0, 1.0)
	await tween.finished

	blur_effect.visible = false

	effect_running = false

func respawn_timer():
	var player = get_tree().current_scene.get_node("Player")
	await get_tree().create_timer(1.2).timeout
	player.global_position = respawn_position
	
