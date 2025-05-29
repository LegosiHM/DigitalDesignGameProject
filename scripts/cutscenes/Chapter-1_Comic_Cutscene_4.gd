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
# PANEL TARGET POSITIONS
# ---------------------------
# Exported landing positions for each comic panel after sliding into view
@export var Panel1: Vector2
@export var Panel2: Vector2

# ---------------------------
# ENTRY DIRECTION SETTINGS
# ---------------------------
# -1 = From left, 1 = From right
@export var panel_entry_directions: Array[int] = [-1, 1]

# ---------------------------
# CUTSCENE REMINDER SETTINGS
# ---------------------------
@export var idle_time_threshold: float = 3.0      # Time of no input before showing reminder
@export var blink_speed: float = 2.0              # Blink animation speed for the reminder
@export var target_opacity: float = 0.5           # Max reminder alpha when blinking

# ---------------------------
# SCENE TRANSITIONS
# ---------------------------
@export var target_cutscene = ""                  # Optional: next cutscene to jump to
@export var target_level = "res://Scenes/levels/Chapter01_Prologue/1-1_Introduction.tscn"

# ---------------------------
# CONSTANTS
# ---------------------------
const PANEL_SLIDE_DURATION := 0.5                 # Time to slide each panel
const SKIP_HOLD_TIME := 2.0                       # Time to hold ESC to skip
const FINAL_CLICK_DELAY := 0.1                    # Delay to prevent instant click-through

# ---------------------------
# INTERNAL STATE
# ---------------------------
var panels = []                                   # Actual panel nodes
var target_positions = []                         # Landing positions from exported values
var entry_directions = []                         # Computed directions per panel
var current_panel_index := -1                     # Index of current panel

var idle_timer: float = 0.0
var reminder_visible: bool = false
var fade_in_progress: bool = false
var current_opacity: float = 0.0

var skip_timer: float = 0.0
var holding_skip: bool = false

# ---------------------------
# READY FUNCTION
# ---------------------------
func _ready():
	reminder_label.modulate.a = 0.0  # Hide reminder initially
	panels = panel_container.get_children()

	# Hide skip ring UI
	skip_ring.visible = false
	skip_ring.value = 0
	skip_label.visible = false

	if panels.is_empty():
		print("⚠ ERROR: No panels found! Make sure PanelContainer has children.")
		return

	var screen_width = get_viewport_rect().size.x

	# Load target positions
	target_positions = [Panel1, Panel2]

	# Clone exported directions and fix if needed
	entry_directions = panel_entry_directions.duplicate()
	if entry_directions.size() != panels.size():
		print("⚠ WARNING: Entry directions count doesn't match panel count. Fixing.")
		entry_directions.resize(panels.size())
		for i in range(entry_directions.size()):
			if typeof(entry_directions[i]) != TYPE_INT:
				entry_directions[i] = 1  # Default to right

	if target_positions.size() != panels.size():
		print("⚠ WARNING: Target positions count doesn't match panel count. Fixing.")
		target_positions.resize(panels.size())

	# Start panels offscreen
	for i in range(panels.size()):
		var start_x = screen_width if entry_directions[i] == 1 else -panels[i].size.x
		panels[i].position = Vector2(start_x, target_positions[i].y)

# ---------------------------
# INPUT HANDLER
# ---------------------------
func _input(event):
	if event is InputEventMouseButton and event.pressed:
		show_next_panel()

# ---------------------------
# PANEL TRANSITION FUNCTION
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
		
		var tween = create_tween()
		tween.tween_property(panel, "position", target_pos, PANEL_SLIDE_DURATION)\
			 .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

		# If last panel shown, wait for a click before changing scene
		if current_panel_index + 1 >= panels.size():
			await tween.finished
			reminder_label.modulate.a = 1.0
			await get_tree().create_timer(FINAL_CLICK_DELAY).timeout
			await wait_for_click()
			reminder_label.modulate.a = 0.0
			get_tree().change_scene_to_file(target_level)

# ---------------------------
# WAIT FOR PLAYER TO CLICK
# ---------------------------
func wait_for_click() -> void:
	while true:
		await get_tree().process_frame
		if Input.is_action_just_pressed("click"):
			break

# ---------------------------
# PROCESS: Handle blinking and skip logic
# ---------------------------
func _process(delta: float):
	# Reset idle timer on click
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

	# Fade in reminder, then blink
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

	# ESC key hold-to-skip logic
	if not holding_skip and Input.is_action_pressed("ui_cancel"):
		holding_skip = true
		skip_ring.visible = true
		skip_label.visible = true

	if holding_skip:
		if Input.is_action_pressed("ui_cancel"):
			skip_timer += delta
			skip_ring.value = skip_timer

			if skip_timer >= SKIP_HOLD_TIME:
				skip_cutscene()
	else:
		# ESC was released too soon → reset
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
