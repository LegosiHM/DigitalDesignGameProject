extends Node2D

func _ready() -> void:
	DialogManager.register_panel_sequence([
		$Gatekeeper01,
		$Gatekeeper02,
		$Gatekeeper01,
		$Gatekeeper01
	])
