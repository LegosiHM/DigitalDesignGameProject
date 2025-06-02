# Example script attached to the slider node

extends HSlider

func _ready():
	value = AudioServer.get_bus_volume_db(0) # 0 is usually the Master bus

func _on_value_changed(value_db: float) -> void:
	Global.master_volume_db = value_db
	AudioServer.set_bus_volume_db(0, value_db)
