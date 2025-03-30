extends Node2D

var respawn_position: Vector2
var respawn_scene: PackedScene

func set_respawn_position(position: Vector2, scene: PackedScene) -> void:
	respawn_position = position
	respawn_scene = scene

func respawn_player() -> void:
	var scene = get_tree().current_scene
	var blur_effect = scene.get_node("RespawnEffect")
	var material := blur_effect.material as ShaderMaterial

	blur_effect.visible = true

	var tween := get_tree().create_tween()
	tween.tween_property(material, "shader_param/blur_strength", 10.0, 0.3)
	tween.tween_property(material, "shader_param/blur_strength", 0.0, 0.3)

	await tween.finished

	blur_effect.visible = false
	if respawn_scene:
		get_tree().change_scene_to(respawn_scene)
		await get_tree().process_frame
		get_tree().current_scene.get_node("Player").global_position = respawn_position
