extends Node2D

var respawn_position: Vector2
var respawn_scene: PackedScene

func set_respawn_position(position: Vector2, scene: PackedScene) -> void:
	respawn_position = position
	respawn_scene = scene

func respawn_player() -> void:
	if respawn_scene:
		get_tree().change_scene_to(respawn_scene)

		get_tree().current_scene.get_node("Player").global_position = respawn_position
