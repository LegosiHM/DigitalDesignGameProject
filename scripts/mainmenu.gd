extends Control

@onready var normal_layer := $NewGameButton/HoverLayer
var tween

var hover_offset := 380      # adjust to match your button
var transition_time := 0.2
@export var target_scene := "res://Scenes/cutscenes/Chapter-1_Comic_Cutscene_1.tscn"  # set to your actual target

func _ready():
	_reset()

func _reset():
	normal_layer.position = normal_layer.position

func _on_new_game_button_mouse_entered():
	if tween and tween.is_running():
		tween.kill()
	tween = create_tween()
	tween.tween_property(
		normal_layer,
		"position:x",
		hover_offset,
		transition_time
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _on_new_game_button_mouse_exited():
	if tween and tween.is_running():
		tween.kill()
	tween = create_tween()
	tween.tween_property(
		normal_layer,
		"position:x",
		78,
		transition_time
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


func _on_new_game_button_pressed() -> void:
	get_tree().change_scene_to_file(target_scene)
