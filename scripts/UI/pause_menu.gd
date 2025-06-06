extends CanvasLayer

@onready var pause_panel = $ColorRect
@onready var resume_button = get_node_or_null("CenterContainer/VBoxContainer/ResumeButton")
@onready var exit_button = get_node_or_null("CenterContainer/VBoxContainer/ExitButton")
@onready var transition_rect: ColorRect = get_node_or_null("CanvasLayer/Scenes_Transition")

var allowed_scenes := [
	"1-1_Introduction",
	"1-2_HighJumpPractice",
	"1-3_Ability Practice",
	"1-4_PushAndLedgeGrabbingPractice",
	"1-5_Combine",
	"1-6_InsideTemple",
	"1-7_Flee1",
	"1-8_Flee2",
	"1-9_Flee3",
	"1-12_Flee4",
	"2-1_MeetCleopatra",
	"2-2-0_FollowCleopatra1",
	"2-2-1_Puzzle",
	"2-2-2_Puzzle",
	"2-3_FollowCleopatra2",
	"2-4_FollowCleopatra3",
	"2-5_MeetCleopatra2",
	"2-6_MeetMark1",
	"2-7_MeetMark2",
	"2-8-0_GoToTown",
	"2-8-1_Puzzle",
	"2-8-2_Puzzle",
	"2-9_MeetCouple1",
	"2-10_MeetCouple2",
	"2-11_MeetCouple3",
	"2-12_InTemple1",
	"3-1_BookHub_Boil",
	"2-13_Blood",
	"2-14_Frog",
	"2-16_WildAnimal",
	"2-17_MeetOctavia",
	"1-10_MeetMedjed1",
	"1-11_MeetMedjed2"
]

func _ready():
	# Listen for Esc key globally
	set_process_unhandled_input(true)

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		if _can_pause_here():
			if not Global.is_changing_scene:
				toggle_pause()

func toggle_pause():
	if get_tree().paused:
		resume_game()
	else:
		pause_game()

func pause_game():
	get_tree().paused = true
	pause_panel.visible = true

func resume_game():
	get_tree().paused = false
	pause_panel.visible = false

func _on_resume_pressed():
	resume_game()

func _on_exit_pressed():
	toggle_pause()
	
	Global.current_level = get_tree().current_scene.scene_file_path
	SaveManager.save_game()
	
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
	
	get_tree().change_scene_to_file("res://Scenes/Mainmenu.tscn")

func _can_pause_here() -> bool:
	var scene_path := get_tree().current_scene.scene_file_path
	var scene_name := scene_path.get_file().get_basename()  # gets just "1-1_Introduction" from the full path
	return scene_name in allowed_scenes
