extends Node2D

func _ready():
	DialogManager.register_panel_sequence([
		$"Gatekeeper01",  # ✅ First click advances to...
		$"Gatekeeper02",  # ✅ This one, even if it's not clicked
		$"Gatekeeper01",  # ✅ Then back to Gatekeeper01
		$"Gatekeeper01"
	])
