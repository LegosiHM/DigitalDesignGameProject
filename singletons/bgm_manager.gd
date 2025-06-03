extends AudioStreamPlayer2D

var current_bgm: String = ""
var last_scene_name: String = ""


var SCENE_BGM_MAP: Dictionary = {
	# Chapter 1 Prologue
	"1-1_Introduction": "res://assets/SFX/BGM/BGM_Chapter_CH1Prologue_v01.mp3",
	"1-2_HighJumpPractice": "res://assets/SFX/BGM/BGM_Chapter_CH1Prologue_v01.mp3",
	"1-3_Ability Practice": "res://assets/SFX/BGM/BGM_Chapter_CH1Prologue_v01.mp3",
	"1-4_PushAndLedgeGrabbingPractice": "res://assets/SFX/BGM/BGM_Chapter_CH1Prologue_v01.mp3",
	"1-5_Combine": "res://assets/SFX/BGM/BGM_Chapter_CH1Prologue_v01.mp3",
	"1-6_InsideTemple": "res://assets/SFX/BGM/BGM_Chapter_CH1Prologue_v01.mp3",
	"1-7_Flee1": "res://assets/SFX/BGM/BGM_Chapter_CH1Prologue_v01.mp3",
	"1-8_Flee2": "res://assets/SFX/BGM/BGM_Chapter_CH1Prologue_v01.mp3",
	"1-9_Flee3": "res://assets/SFX/BGM/BGM_Chapter_CH1Prologue_v01.mp3",
	"1-12_Flee4": "",

	# Chapter 2
	"2-1_MeetCleopatra": "res://assets/SFX/BGM/BGM_Chapter_CH2_v01.mp3",
	"2-2-0_FollowCleopatra1": "res://assets/SFX/BGM/BGM_Chapter_CH2_v01.mp3",
	"2-2-1_Puzzle": "res://assets/SFX/BGM/BGM_Chapter_CH2_v01.mp3",
	"2-2-2_Puzzle": "res://assets/SFX/BGM/BGM_Chapter_CH2_v01.mp3",
	"2-3_FollowCleopatra2": "res://assets/SFX/BGM/BGM_Chapter_CH2_v01.mp3",
	"2-4_FollowCleopatra3": "res://assets/SFX/BGM/BGM_Chapter_CH2_v01.mp3",
	"2-5_MeetCleopatra2": "res://assets/SFX/BGM/BGM_Chapter_CH2_v01.mp3",
	"2-6_MeetMark1": "res://assets/SFX/BGM/BGM_Chapter_CH2_v01.mp3",
	"2-7_MeetMark2": "res://assets/SFX/BGM/BGM_Chapter_CH2_v01.mp3",
	"2-8-0_GoToTown": "res://assets/SFX/BGM/BGM_Chapter_CH2_v01.mp3",
	"2-8-1_Puzzle": "res://assets/SFX/BGM/BGM_Chapter_CH2_v01.mp3",
	"2-8-2_Puzzle": "res://assets/SFX/BGM/BGM_Chapter_CH2_v01.mp3",
	"2-9_MeetCouple1": "res://assets/SFX/BGM/BGM_Chapter_CH2_v01.mp3",
	"2-10_MeetCouple2": "res://assets/SFX/BGM/BGM_Chapter_CH2_v01.mp3",
	"2-11_MeetCouple3": "res://assets/SFX/BGM/BGM_Chapter_CH2_v01.mp3",
	"2-12_InTemple1": "res://assets/SFX/BGM/BGM_Chapter_CH2_v01.mp3",

	# Chapter 3 Epilogue
	"3-1_BookHub_Boil": "res://assets/SFX/BGM/BGM_Chapter_CH3Epilogue_v01.mp3",

	# Medjed Plague
	"2-13_Blood": "res://assets/SFX/BGM/BGM_Chapter_MedjedDimensionPlague_v01.mp3",
	"2-14_Frog": "res://assets/SFX/BGM/BGM_Chapter_MedjedDimensionPlague_v01.mp3",
	"2-15_Lice": "res://assets/SFX/BGM/BGM_Chapter_MedjedDimensionPlague_v01.mp3",
	"2-16_WildAnimal": "res://assets/SFX/BGM/BGM_Chapter_MedjedDimensionPlague_v01.mp3",
	"2-17_MeetOctavia": "res://assets/SFX/BGM/BGM_Chapter_MedjedDimensionPlague_v01.mp3",

	# Medjed Dim
	"1-10_MeetMedjed1": "res://assets/SFX/BGM/BGM_Chapter_MedjedDimension_v01.mp3",
	"1-11_MeetMedjed2": "res://assets/SFX/BGM/BGM_Chapter_MedjedDimension_v01.mp3",
	
	# Cutscenes
	"Chapter-1_Comic_Cutscene_1": "res://assets/SFX/BGM/BGM_Cutscene_Start_v01.mp3",
	"Chapter-1_Comic_Cutscene_2": "res://assets/SFX/BGM/BGM_Cutscene_Start_v01.mp3",
	"Chapter-1_Comic_Cutscene_3": "res://assets/SFX/BGM/BGM_Cutscene_Start_v01.mp3",
	"Chapter-1_Comic_Cutscene_4": "res://assets/SFX/BGM/BGM_Cutscene_Start_v01.mp3",
	
	"Chapter-2_Comic_Cutscene_1": "res://assets/SFX/BGM/BGM_Cutscene_EndPrologue_v01.mp3",
	"Chapter-2_Comic_Cutscene_2": "res://assets/SFX/BGM/BGM_Cutscene_EndPrologue_v01.mp3",
	"Chapter-2_Comic_Cutscene_3": "res://assets/SFX/BGM/BGM_Cutscene_EndPrologue_v01.mp3",
	"Chapter-2_Comic_Cutscene_4": "res://assets/SFX/BGM/BGM_Cutscene_EndPrologue_v01.mp3",
	"Chapter-2_Comic_Cutscene_5": "res://assets/SFX/BGM/BGM_Cutscene_EndPrologue_v01.mp3",

	# Main Menu
	"MainMenu": "res://assets/SFX/BGM/BGM_Menu_MainMenu_v01.mp3",
	
	#End Epilogue
	"Chapter-3_Comic_Cutscene_1": "res://assets/SFX/BGM/BGM_Cutscene_EndEpilogue_v01.mp3",
	"Chapter-3_Comic_Cutscene_2": "res://assets/SFX/BGM/BGM_Cutscene_EndEpilogue_v01.mp3",
	"Credit": "res://assets/SFX/BGM/BGM_Cutscene_EndEpilogue_v01.mp3",
	"TheEnd": "res://assets/SFX/BGM/BGM_Cutscene_EndEpilogue_v01.mp3"
	}

func _ready():
	var current_scene := get_tree().current_scene
	if current_scene:
		var scene_name := current_scene.name
		last_scene_name = scene_name
		_update_bgm(scene_name)

func _process(_delta):
	var current_scene := get_tree().current_scene
	if current_scene == null:
		return

	var scene_name: String = current_scene.name

	if scene_name != last_scene_name:
		last_scene_name = scene_name
		_update_bgm(scene_name)


func _update_bgm(scene_name: String):
	var bgm_path: String = SCENE_BGM_MAP.get(scene_name, "")
	if bgm_path == "":
		print("🎵 No BGM defined for scene:", scene_name)
		return

	if current_bgm == bgm_path:
		# Same song already playing
		return

	var bgm_stream = load(bgm_path)
	if bgm_stream is AudioStream:
		current_bgm = bgm_path
	
		if bgm_stream is AudioStreamOggVorbis or bgm_stream is AudioStreamMP3 or bgm_stream is AudioStreamWAV:
			bgm_stream.loop = true
	
		_fade_to(bgm_stream)
		print("🎶 Playing BGM:", bgm_path)
	else:
		push_error("❌ Failed to load BGM: " + bgm_path)

func _fade_to(new_stream: AudioStream):
	var tween := create_tween()
	tween.tween_property(self, "volume_db", -40.0, 1.0)
	tween.tween_callback(func():
		self.stop()
		self.stream = new_stream
		self.play()
		self.volume_db = -40.0
	)
	tween.tween_property(self, "volume_db", 0.0, 1.0)
