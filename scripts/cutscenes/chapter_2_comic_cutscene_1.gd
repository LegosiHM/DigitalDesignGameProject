extends Control

# -------------------------------
# NODE REFERENCES
# -------------------------------
@onready var panel_container = $PanelContainer
@onready var reminder_label = $Reminder
@onready var skip_ring: TextureProgressBar = $SkipRing
@onready var skip_label: Label = $SkipLabel

# -------------------------------
# PANEL POSITIONS (Landing Spots)
# -------------------------------
@export var Panel1: Vector2

# -------------------------------
# PANEL ENTRY DIRECTIONS (Editable)
# -1 = from left, 1 = from right
# -------------------------------
@export var panel_entry_directions: Array[int] = [-1]

# -------------------------------
# REMINDER / BLINK SETTINGS
# -------------------------------
@export var idle_time_threshold: float = 3.0
@export var blink_speed: float = 2.0
@export var target_opacity: float = 0.5

# -------------------------------
# SCENE TRANSITION TARGETS
# -------------------------------
@export var target_cutscene: String = "res://Scenes/cutscenes/Chapter-2_Comic_Cutscene_2.tscn"
@export var target_level: String = "res://Scenes/levels/Chapter02_Kernel/2-1_MeetCleopatra.tscn"

# -------------------------------
# STATE VARIABLES
# -------------------------------
var panels: Array = []
var target_positions: Array = []
var entry_directions: Array = []
var current_panel_index: int = -1

var idle_timer: float = 0.0
var reminder_visible: bool = false
var fade_in_progress: bool = false
var current_opacity: float = 0.0

var skip_timer: float = 0.0
var holding_skip: bool = false

# -------------------------------
# READY FUNCTION - SETUP
# -------------------------------
func _ready():
	reminder_label.modulate.a = 0.0
	panels = panel_container.get_children()

	skip_ring.visible = false
	skip_ring.value = 0
	skip_label.visible = false

	if panels.size() == 0:
		print("⚠ ERROR: No panels found! Make sure PanelContainer has children.")
		return

	var screen_width = get_viewport_rect().size.x

	# Assign target positions manually
	target_positions = [Panel1]

	# Clone the exported entry directions and fix if necessary
	entry_directions = panel_entry_directions.duplicate()
	if entry_directions.size() != panels.size():
		print("⚠ WARNING: panel_entry_directions size mismatch. Adjusting.")
		entry_directions.resize(panels.size())
		for i in range(entry_directions.size()):
			if typeof(entry_directions[i]) != TYPE_INT:
				entry_directions[i] = 1  # Default to right side

	# Start all panels offscreen
	for i in range(panels.size()):
		var start_x = screen_width if entry_directions[i] == 1 else -panels[i].size.x
		panels[i].position = Vector2(start_x, target_positions[i].y)

# -------------------------------
# MOUSE INPUT TO ADVANCE PANELS
# -------------------------------
func _input(event):
	if event is InputEventMouseButton and event.pressed:
		show_next_panel()

# -------------------------------
# SLIDE NEXT PANEL INTO PLACE
# -------------------------------
func show_next_panel():
	if current_panel_index + 1 < panels.size():
		current_panel_index += 1
		var panel = panels[current_panel_index]
		var target_pos = target_positions[current_panel_index]

		var tween = create_tween()
		tween.tween_property(panel, "position", target_pos, 0.5)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

		# If this is the last panel, wait for final click
		if current_panel_index + 1 >= panels.size():
			await tween.finished
			reminder_label.modulate.a = 1.0
			await wait_for_click()
			reminder_label.modulate.a = 0.0
			get_tree().change_scene_to_file(target_cutscene)

# -------------------------------
# WAIT FOR PLAYER FINAL CONFIRM
# -------------------------------
func wait_for_click() -> void:
	while true:
		await get_tree().process_frame
		if Input.is_action_just_pressed("click"):
			break

# -------------------------------
# PROCESS: REMINDER + ESC-SKIP
# -------------------------------
func _process(delta: float):
	# Reset idle reminder on click
	if Input.is_action_just_pressed("click"):
		idle_timer = 0.0
		if reminder_visible:
			reminder_visible = false
			fade_in_progress = false
			reminder_label.modulate.a = 0.0
	else:
		idle_timer += delta
		if idle_timer >= idle_time_threshold and not reminder_visible:
			reminder_visible = true
			fade_in_progress = true
			current_opacity = 0.0

	# Reminder blinking effect
	if reminder_visible:
		if fade_in_progress:
			current_opacity += delta
			var alpha = clamp(current_opacity, 0.0, target_opacity)
			reminder_label.modulate.a = alpha
			if alpha >= target_opacity:
				fade_in_progress = false
		else:
			var blink_opacity = 1 + (target_opacity - 1) * \
				(0.5 + 0.5 * sin(blink_speed * Time.get_ticks_msec() / 1000.0))
			reminder_label.modulate.a = blink_opacity

	# ESC hold-to-skip logic
	if not holding_skip and Input.is_action_pressed("ui_cancel"):
		holding_skip = true
		skip_ring.visible = true
		skip_label.visible = true

	if holding_skip:
		if Input.is_action_pressed("ui_cancel"):
			skip_timer += delta
			skip_ring.value = skip_timer
			if skip_timer >= 2.0:
				skip_cutscene()
	else:
		holding_skip = false
		skip_timer = 0.0
		skip_ring.value = 0
		skip_ring.visible = false
		skip_label.visible = false

# -------------------------------
# SKIP SCENE IMMEDIATELY
# -------------------------------
func skip_cutscene():
	get_tree().change_scene_to_file(target_level)
