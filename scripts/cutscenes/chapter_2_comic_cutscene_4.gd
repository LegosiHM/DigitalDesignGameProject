extends Control

# -------------------------------------
# NODE REFERENCES
# -------------------------------------
@onready var panel_container = $PanelContainer
@onready var reminder_label = $Reminder
@onready var skip_ring: TextureProgressBar = $SkipRing
@onready var skip_label: Label = $SkipLabel
@onready var audio_panel_click: AudioStreamPlayer2D = $AudioStreamPlayer2D

# -------------------------------------
# PANEL FINAL POSITIONS (exported)
# These are the target positions where each panel will slide into.
# -------------------------------------
@export var Panel1: Vector2
@export var Panel2: Vector2

# -------------------------------------
# PANEL ENTRY DIRECTION (exported)
# -1 = enter from left, 1 = enter from right
# Should match the number of panels in container
# -------------------------------------
@export var entry_directions: Array[int] = [-1, 1]

# -------------------------------------
# IDLE REMINDER SETTINGS
# -------------------------------------
@export var idle_time_threshold: float = 3.0  # Time in seconds before showing reminder
@export var blink_speed: float = 2.0          # Frequency of blinking effect
@export var target_opacity: float = 0.5       # Max alpha value for blinking reminder

# -------------------------------------
# SCENE TRANSITION TARGETS
# -------------------------------------
@export var target_cutscene: String = "res://Scenes/cutscenes/Chapter-2_Comic_Cutscene_5.tscn"
@export var target_level: String = "res://Scenes/levels/Chapter02_Kernel/2-1_MeetCleopatra.tscn"

# -------------------------------------
# INTERNAL STATE TRACKERS
# -------------------------------------
var panels: Array = []                  # Holds panel node references
var target_positions: Array = []        # Final landing positions for each panel
var current_panel_index: int = -1       # Index of the panel currently being shown

var idle_timer: float = 0.0
var reminder_visible: bool = false
var fade_in_progress: bool = false
var current_opacity: float = 0.0

var skip_timer: float = 0.0
var holding_skip: bool = false

# -------------------------------------
# _ready(): Setup everything
# -------------------------------------
func _ready():
	# Hide blinking reminder initially
	reminder_label.modulate.a = 0.0

	# Get child panels from container
	panels = panel_container.get_children()

	# Setup skip ring visuals
	skip_ring.visible = false
	skip_ring.value = 0
	skip_label.visible = false

	# Ensure there are panels
	if panels.is_empty():
		print("⚠ ERROR: No panels found! Check PanelContainer children.")
		return

	var screen_width = get_viewport_rect().size.x

	# Assign panel positions from exported values
	target_positions = [Panel1, Panel2]

	# Ensure direction list matches number of panels
	if entry_directions.size() != panels.size():
		print("⚠ WARNING: entry_directions mismatch with panel count. Resizing.")
		entry_directions.resize(panels.size())

	# Ensure target position list matches number of panels
	if target_positions.size() != panels.size():
		print("⚠ WARNING: target_positions mismatch with panel count. Resizing.")
		target_positions.resize(panels.size())

	# Position panels offscreen before animation
	for i in range(panels.size()):
		var direction = entry_directions[i]
		var panel = panels[i]
		var offscreen_x = screen_width if direction == 1 else -panel.size.x
		panel.position = Vector2(offscreen_x, target_positions[i].y)

# -------------------------------------
# INPUT HANDLING: Click to advance
# -------------------------------------
func _input(event):
	if event is InputEventMouseButton and event.pressed:
		show_next_panel()

# -------------------------------------
# show_next_panel(): Animate panel into place
# -------------------------------------
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
		
		# Tween panel into view
		var tween = create_tween()
		tween.tween_property(panel, "position", target_pos, 0.5)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

		# If this is the final panel, trigger next cutscene
		if current_panel_index + 1 >= panels.size():
			await tween.finished
			reminder_label.modulate.a = 1.0
			await wait_for_click()
			reminder_label.modulate.a = 0.0
			get_tree().change_scene_to_file(target_cutscene)

# -------------------------------------
# wait_for_click(): Wait for user interaction
# -------------------------------------
func wait_for_click() -> void:
	while true:
		await get_tree().process_frame
		if Input.is_action_just_pressed("click"):
			break

# -------------------------------------
# _process(): Idle reminder & skip logic
# -------------------------------------
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

	# Blink animation logic
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

	# ESC HOLD-TO-SKIP LOGIC
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
# skip_cutscene(): Jump to next level
# -------------------------------------
func skip_cutscene():
	get_tree().change_scene_to_file(target_level)
