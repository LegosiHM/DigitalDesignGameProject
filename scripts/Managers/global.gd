extends Node2D

var respawn_manager

func _ready():
	respawn_manager = get_tree().get_root().get_node("RespawnManager")
