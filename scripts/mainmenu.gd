extends Control

@onready var newgame_hover_layer := $NewGameButton/HoverLayer
@onready var load_hover_layer := $LoadButton/HoverLayer
@onready var load_button := $LoadButton/Button
var tween

var hover_offset := 380      # adjust to match your button
var transition_time := 0.2
@export var target_scene := "res://Scenes/cutscenes/Chapter-1_Comic_Cutscene_1.tscn"  # set to your actual target

@onready var audio_click = $AudioStreamPlayer2D
@onready var transition_rect: ColorRect = $CanvasLayer/Scenes_Transition

func _ready():
	_reset()
	
	if not SaveManager.has_save():
		load_button.disabled = true
		$LoadButton.modulate = Color(0.3, 0.3, 0.3, 1.0)
	else:
		load_button.disabled = false
		$LoadButton.modulate = Color(1, 1, 1, 1)

func _reset():
	newgame_hover_layer.position = newgame_hover_layer.position
	load_hover_layer.position = load_hover_layer.position

func _on_new_game_button_mouse_entered():
	tween = create_tween()
	tween.tween_property(
		newgame_hover_layer,
		"position:x",
		hover_offset,
		transition_time
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _on_new_game_button_mouse_exited():
	tween = create_tween()
	tween.tween_property(
		newgame_hover_layer,
		"position:x",
		78,
		transition_time
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


func _on_new_game_button_pressed() -> void:
	audio_click.play()
	await audio_click.finished
	Global.has_hj_power = false
	Global.current_level = "res://Scenes/levels/Chapter01_Prologue/1-1_Introduction.tscn"
	SaveManager.save_game()
	if not transition_rect or not transition_rect.material:
		push_error("ERROR: Cannot animate transition, ColorRect or material is missing!")
		get_tree().change_scene_to_file(target_scene)  # Fallback to instant switch
		return
		
	
	var tween = create_tween()

	# Fade in effect using custom shader (fade 0 → 1)
	tween.tween_property(
		transition_rect.material, "shader_parameter/in_out", 
		1.0, 0.1
	).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)

	# Slide effect: moves shader to cover screen (1.0 → -1.5)
	tween.tween_property(
		transition_rect.material, "shader_parameter/position", 
		-1.5, 0.5
	).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)

	await tween.finished  # Wait for animation before changing scenes
	get_tree().change_scene_to_file(target_scene)


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_load_button_pressed() -> void:
	if load_button.disabled:
		return
	
	if not SaveManager.has_save():
			return
		
	SaveManager.load_game()
	audio_click.play()
	await audio_click.finished
	if not transition_rect or not transition_rect.material:
		push_error("ERROR: Cannot animate transition, ColorRect or material is missing!")
		get_tree().change_scene_to_file(target_scene)  # Fallback to instant switch
		return
		
	
	var tween = create_tween()

	# Fade in effect using custom shader (fade 0 → 1)
	tween.tween_property(
		transition_rect.material, "shader_parameter/in_out", 
		1.0, 0.1
	).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)

	# Slide effect: moves shader to cover screen (1.0 → -1.5)
	tween.tween_property(
		transition_rect.material, "shader_parameter/position", 
		-1.5, 0.5
	).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)

	await tween.finished  # Wait for animation before changing scenes
	if Global.current_level != "":
		get_tree().change_scene_to_file(Global.current_level)


func _on_button_pressed() -> void:
	SaveManager.delete_save()


func _on_load_button_mouse_entered() -> void:
	if load_button.disabled:
		return
	
	tween = create_tween()
	tween.tween_property(
		load_hover_layer,
		"position:x",
		450,
		transition_time
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _on_load_button_mouse_exited() -> void:
	if load_button.disabled:
		return
		
	tween = create_tween()
	tween.tween_property(
		load_hover_layer,
		"position:x",
		78,
		transition_time
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
