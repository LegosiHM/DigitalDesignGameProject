extends Control

@onready var panel_container = $PanelContainer
@export var Panel1 = Vector2()
@export var Panel2 = Vector2()
@export var Panel3 = Vector2()
@export var Panel4 = Vector2()
var panels = []
var target_positions = []  # Stores the final position of each panel
var entry_directions = []  # Controls if a panel enters from left (-1) or right (1)
var current_panel_index = -1  # Tracks the current panel being displayed

func _ready():
	panels = panel_container.get_children()

	if panels.size() == 0:
		print("⚠ ERROR: No panels found! Make sure PanelContainer has children.")
		return  # Prevent crashes

	var screen_width = get_viewport_rect().size.x
	var screen_height = get_viewport_rect().size.y

	# Define the exact positions where panels should land
	target_positions = [
		Panel1,   # Panel 1 position
		Panel2,  # Panel 2 position
		Panel3,  # Panel 3 position
		Panel4   # Panel 4 position
	]

	# Define the entry direction for each panel (-1 = left, 1 = right)
	entry_directions = [-1, 1, -1, 1]  # First panel enters from right, second from left, etc.

	# Ensure the lists match the actual number of panels
	if target_positions.size() != panels.size():
		print("⚠ WARNING: target_positions does not match panel count! Fixing it.")
		target_positions.resize(panels.size())

	if entry_directions.size() != panels.size():
		print("⚠ WARNING: entry_directions does not match panel count! Fixing it.")
		entry_directions.resize(panels.size())

	# Initialize panels off-screen based on their entry direction
	for i in range(panels.size()):
		var start_x = screen_width if entry_directions[i] == 1 else -panels[i].size.x
		panels[i].position = Vector2(start_x, target_positions[i].y)

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		show_next_panel()

func show_next_panel():
	if current_panel_index + 1 < panels.size():
		current_panel_index += 1
		var panel = panels[current_panel_index]
		var target_pos = target_positions[current_panel_index]
		var tween = create_tween()
		tween.tween_property(panel, "position", target_pos, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

		# If the screen is full, transition to the next scene
		if current_panel_index + 1 >= panels.size():
			await get_tree().create_timer(1.5).timeout
			get_tree().change_scene_to_file("res://scenes/cutscenes/chapter_1_comic_cutscene_3.tscn")
