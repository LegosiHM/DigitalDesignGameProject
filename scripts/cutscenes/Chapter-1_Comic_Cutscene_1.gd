extends Control

# ---------------------------
# NODE REFERENCES
# ---------------------------
@onready var panel_container = $PanelContainer
@onready var reminder_label = $Reminder
@onready var skip_ring: TextureProgressBar = $SkipRing
@onready var skip_label: Label = $SkipLabel
@onready var audio_panel_click: AudioStreamPlayer2D = $AudioStreamPlayer2D

# ---------------------------
# PANEL FINAL POSITIONS
# ---------------------------
@export var Panel1 = Vector2()
@export var Panel2 = Vector2()
@export var Panel3 = Vector2()
@export var Panel4 = Vector2()
@export var Panel5 = Vector2()

# ---------------------------
# PANEL ENTRY DIRECTIONS (Editable)
# -1 = enter from left, 1 = enter from right
# ---------------------------
@export var panel_entry_directions: Array[int] = [-1, 1, -1, 1, 1]

# ---------------------------
# REMINDER BLINK BEHAVIOR
# ---------------------------
@export var idle_time_threshold: float = 3.0
@export var blink_speed: float = 2.0
@export var target_opacity: float = 0.5

# ---------------------------
# CUTSCENE FLOW DESTINATIONS
# ---------------------------
@export var target_cutscene = "res://Scenes/cutscenes/Chapter-1_Comic_Cutscene_2.tscn"
@export var target_level = "res://Scenes/levels/Chapter01_Prologue/1-1_Introduction.tscn"

# ---------------------------
# INTERNAL STATE VARIABLES
# ---------------------------
var panels = []
var target_positions = []
var entry_directions = []
var current_panel_index = -1

var idle_timer: float = 0.0
var reminder_visible: bool = false
var fade_in_progress: bool = false
var current_opacity: float = 0.0

var skip_timer: float = 0.0
var holding_skip: bool = false

# ---------------------------
# CONSTANTS FOR TIMING
# ---------------------------
const FINAL_TWEEN_DURATION := 0.5
const FINAL_WAIT_DELAY := 0.2
const SKIP_HOLD_DURATION := 2.0

# ---------------------------
# READY FUNCTION
# ---------------------------
func _ready():
	reminder_label.modulate.a = 0.0
	panels = panel_container.get_children()

	skip_ring.visible = false
	skip_ring.value = 0
	skip_label.visible = false

	if panels.is_empty():
		print("⚠ ERROR: No panels found! Make sure PanelContainer has children.")
		return

	var screen_width = get_viewport_rect().size.x

	# Setup final target positions
	target_positions = [Panel1, Panel2, Panel3, Panel4, Panel5]

	# Setup entry directions (copied from exported array)
	entry_directions = panel_entry_directions.duplicate()
	if entry_directions.size() != panels.size():
		print("⚠ WARNING: panel_entry_directions count doesn't match panel count. Fixing.")
		entry_directions.resize(panels.size())
		for i in range(panels.size()):
			if typeof(entry_directions[i]) != TYPE_INT:
				entry_directions[i] = 1  # Default to entering from right

	if target_positions.size() != panels.size():
		print("⚠ WARNING: target_positions count doesn't match panel count. Fixing.")
		target_positions.resize(panels.size())

	# Start panels off-screen
	for i in range(panels.size()):
		var start_x = screen_width if entry_directions[i] == 1 else -panels[i].size.x
		panels[i].position = Vector2(start_x, target_positions[i].y)

# ---------------------------
# INPUT: Advance on Mouse Click
# ---------------------------
func _input(event):
	if event is InputEventMouseButton and event.pressed:
		show_next_panel()

# ---------------------------
# MAIN PANEL PROGRESSION LOGIC
# ---------------------------
func show_next_panel():
	if current_panel_index + 1 < panels.size():
		current_panel_index += 1
		var panel = panels[current_panel_index]
		var target_pos = target_positions[current_panel_index]

		# 🔊 Clone and play sound for this panel
		var sfx = audio_panel_click.duplicate()
		add_child(sfx)
		sfx.play()
		sfx.finished.connect(sfx.queue_free)  # Clean up after done

		# 🧊 Move panel in
		var tween = create_tween()
		tween.tween_property(panel, "position", target_pos, FINAL_TWEEN_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

		if current_panel_index + 1 == panels.size():
			await tween.finished
			reminder_label.modulate.a = 1.0
			await get_tree().create_timer(FINAL_WAIT_DELAY).timeout
			await wait_for_click()
			reminder_label.modulate.a = 0.0
			get_tree().change_scene_to_file(target_cutscene)


# ---------------------------
# CLICK OR KEYBOARD ACCEPT HANDLER
# ---------------------------
func wait_for_click() -> void:
	while true:
		await get_tree().process_frame
		if Input.is_action_just_pressed("click") or Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("ui_select"):
			break

# ---------------------------
# FRAME-BY-FRAME PROCESSING
# ---------------------------
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

	if reminder_visible:
		if fade_in_progress:
			current_opacity += delta
			var alpha = clamp(current_opacity, 0.0, target_opacity)
			reminder_label.modulate.a = alpha
			if alpha >= target_opacity:
				fade_in_progress = false
		else:
			var blink_opacity = 1 + (target_opacity - 1) * (0.5 + 0.5 * sin(blink_speed * Time.get_ticks_msec() / 1000.0))
			reminder_label.modulate.a = blink_opacity

	# ---------------------------
	# ESC KEY HOLD-TO-SKIP LOGIC
	# ---------------------------
	if not holding_skip and Input.is_action_pressed("ui_cancel"):
		holding_skip = true
		skip_ring.visible = true
		skip_label.visible = true

	if holding_skip:
		if Input.is_action_pressed("ui_cancel"):
			skip_timer += delta
			skip_ring.value = skip_timer

			if skip_timer >= SKIP_HOLD_DURATION:
				skip_cutscene()
	else:
		holding_skip = false
		skip_timer = 0.0
		skip_ring.value = 0
		skip_ring.visible = false
		skip_label.visible = false

# ---------------------------
# ESC SKIP HANDLER
# ---------------------------
func skip_cutscene():
	get_tree().change_scene_to_file(target_level)
