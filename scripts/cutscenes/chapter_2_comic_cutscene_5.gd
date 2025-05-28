extends Control

# -------------------------------------
# NODE REFERENCES
# -------------------------------------
@onready var panel_container = $PanelContainer
@onready var reminder_label = $Reminder
@onready var skip_ring: TextureProgressBar = $SkipRing
@onready var skip_label: Label = $SkipLabel

# -------------------------------------
# PANEL FINAL POSITIONS
# -------------------------------------
@export var Panel1: Vector2  # Position for panel 1 when it slides in

# -------------------------------------
# PANEL ENTRY DIRECTION
# Each panel enters from left (-1) or right (1)
# This list is auto-resized to match panel count
# -------------------------------------
@export var entry_directions: Array[int] = [-1]

# -------------------------------------
# IDLE REMINDER CONFIG
# -------------------------------------
@export var idle_time_threshold: float = 3.0  # Seconds before reminder shows
@export var blink_speed: float = 2.0          # Blinking rate
@export var target_opacity: float = 0.5       # Max alpha for blinking label

# -------------------------------------
# TARGET SCENE PATHS
# -------------------------------------
@export var target_cutscene: String = ""  # Optional: leave empty if unused
@export var target_level: String = "res://Scenes/levels/Chapter02_Kernel/2-1_MeetCleopatra.tscn"

# -------------------------------------
# RUNTIME STATE VARIABLES
# -------------------------------------
var panels: Array = []                # All panel nodes
var target_positions: Array = []      # Final screen positions per panel
var current_panel_index: int = -1     # Which panel is currently shown

var idle_timer: float = 0.0
var reminder_visible: bool = false
var fade_in_progress: bool = false
var current_opacity: float = 0.0

var skip_timer: float = 0.0
var holding_skip: bool = false

# -------------------------------------
# _ready(): Initialize panel positions and UI
# -------------------------------------
func _ready():
	reminder_label.modulate.a = 0.0  # Fully transparent reminder label at start
	panels = panel_container.get_children()  # Get panel nodes
	
	# Prepare skip UI
	skip_ring.visible = false
	skip_ring.value = 0
	skip_label.visible = false

	if panels.is_empty():
		print("⚠ ERROR: No panels found! Check children of PanelContainer.")
		return

	var screen_width = get_viewport_rect().size.x

	# -------------------------------------
	# Panel Targets & Entry Directions Setup
	# -------------------------------------
	target_positions = [Panel1]  # Add more if needed

	# Ensure size of position and direction arrays matches actual panels
	if target_positions.size() != panels.size():
		print("⚠ WARNING: Mismatched target_positions. Resizing to match panel count.")
		target_positions.resize(panels.size())

	if entry_directions.size() != panels.size():
		print("⚠ WARNING: Mismatched entry_directions. Resizing to match panel count.")
		entry_directions.resize(panels.size())

	# Position each panel off-screen based on its entry direction
	for i in range(panels.size()):
		var panel = panels[i]
		var direction = entry_directions[i]
		var start_x = screen_width if direction == 1 else -panel.size.x
		panel.position = Vector2(start_x, target_positions[i].y)

# -------------------------------------
# _input(): Show next panel on mouse click
# -------------------------------------
func _input(event):
	if event is InputEventMouseButton and event.pressed:
		show_next_panel()

# -------------------------------------
# show_next_panel(): Animate a panel into place
# -------------------------------------
func show_next_panel():
	if current_panel_index + 1 < panels.size():
		current_panel_index += 1
		var panel = panels[current_panel_index]
		var target_pos = target_positions[current_panel_index]

		var tween = create_tween()
		tween.tween_property(panel, "position", target_pos, 0.5)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

		# If last panel was shown, trigger scene change
		if current_panel_index + 1 >= panels.size():
			await tween.finished
			reminder_label.modulate.a = 1.0
			await wait_for_click()
			reminder_label.modulate.a = 0.0
			get_tree().change_scene_to_file(target_level)

# -------------------------------------
# wait_for_click(): Blocks until player clicks
# -------------------------------------
func wait_for_click() -> void:
	while true:
		await get_tree().process_frame
		if Input.is_action_just_pressed("click"):
			break

# -------------------------------------
# _process(): Handles reminder fading & ESC to skip
# -------------------------------------
func _process(delta: float):
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

	# Fade reminder in and blink it if idle
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

	# ESC HOLD-TO-SKIP IMPLEMENTATION
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

# -------------------------------------
# skip_cutscene(): Manually skip to target scene
# -------------------------------------
func skip_cutscene():
	get_tree().change_scene_to_file(target_level)
