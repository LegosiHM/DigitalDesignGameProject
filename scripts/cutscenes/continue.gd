extends Control

@onready var label = $Label

func _ready():
	# Start fully transparent
	label.modulate.a = 0.0

	# Create a tween on the scene tree
	var tween := create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Wait for the tween to finish, then change scene
	await tween.finished
	get_tree().change_scene_to_file("res://Scenes/cutscenes/Credit.tscn")  # Change path to your main menu
