extends Node

const SAVE_PATH := "user://savegame.json"

func _ready():
	# Connect when the active scene changes
	get_tree().connect("scene_changed", Callable(self, "_on_scene_changed"))

func _on_scene_changed(new_scene):
	print("Scene changed to: ", new_scene.name)
	load_game()

func save_game():
	var data = {
		"Has_HJ_Power": Global.has_hj_power,
		"current_level": Global.current_level,
		"master_volume_db": Global.master_volume_db,
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t"))
	file.close()

func load_game():
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		var data = JSON.parse_string(file.get_as_text())
		file.close()
		if typeof(data) == TYPE_DICTIONARY:
			Global.has_hj_power = data.get("Has_HJ_Power", false)
			Global.current_level = data.get("current_level", "")
			Global.master_volume_db = data.get("master_volume_db", 0)
			AudioServer.set_bus_volume_db(0, Global.master_volume_db)
