extends Control

# -------------------------------
# NODE REFERENCES
# -------------------------------
@onready var panel_container = $PanelContainer
@onready var reminder_label = $Reminder
@onready var skip_ring: TextureProgressBar = $SkipRing
@onready var skip_label: Label = $SkipLabel
@onready var audio_panel_click: AudioStreamPlayer2D = $AudioStreamPlayer2D

# -------------------------------
# PANEL POSITION EXPORTS
# -------------------------------
@export var Panel1: Vector2 
@export var Panel2: Vector2  
@export var Panel3: Vector2  

# -------------------------------
# PANEL ENTRY DIRECTION EXPORT
# -1 = enter from left, 1 = enter from right
# -------------------------------
@export var entry_directions: Array[int] = [-1,-1,-1]

# -------------------------------
# IDLE REMINDER SETTINGS
# -------------------------------
@export var idle_time_threshold: float = 3.0  # Time in seconds before reminder appears
@export var blink_speed: float = 2.0          # Reminder blinking speed
@export var target_opacity: float = 0.5       # Max opacity for blinking reminder

# -------------------------------
# CUTSCENE TRANSITION TARGETS
# -------------------------------
@export var target_cutscene: String = "res://Scenes/cutscenes/Chapter-2_Comic_Cutscene_4.tscn"
@export var target_level: String = "res://Scenes/levels/Chapter02_Kernel/2-1_MeetCleopatra.tscn"

# -------------------------------
# INTERNAL STATE VARIABLES
# -------------------------------
var panels: Array = []                     # All panel nodes
var target_positions: Array = []           # Final position each panel should move to
var current_panel_index: int = -1          # Tracks which panel is currently active

var idle_timer: float = 0.0
var reminder_visible: bool = false
var fade_in_progress: bool = false
var current_opacity: float = 0.0

var skip_timer: float = 0.0
var holding_skip: bool = false

# -------------------------------
# _ready(): Initializes scene logic
# -------------------------------
func _ready():
	reminder_label.modulate.a = 0.0  # Hide reminder initially
	panels = panel_container.get_children()

	# Setup skip UI
	skip_ring.visible = false
	skip_ring.value = 0
	skip_label.visible = false

	if panels.is_empty():
		print("⚠ ERROR: No panels found! Make sure PanelContainer has children.")
		return

	var screen_width = get_viewport_rect().size.x

	# Add your exported positions manually (currently just Panel1)
	target_positions = [Panel1,Panel2,Panel3]

	# Ensure the exported directions match panel count
	if entry_directions.size() != panels.size():
		print("⚠ WARNING: entry_directions does not match panel count! Fixing...")
		entry_directions.resize(panels.size())
		for i in range(panels.size()):
			if typeof(entry_directions[i]) != TYPE_INT:
				entry_directions[i] = 1  # Default direction: enter from right

	# Ensure target_positions is also safe
	if target_positions.size() != panels.size():
		print("⚠ WARNING: target_positions does not match panel count! Fixing...")
		target_positions.resize(panels.size())

	# Move panels off-screen based on their entry direction
	for i in range(panels.size()):
		var direction = entry_directions[i]
		var panel = panels[i]
		var start_x = screen_width if direction == 1 else -panel.size.x
		panel.position = Vector2(start_x, target_positions[i].y)

# -------------------------------
# _input(): Handle user clicking
# -------------------------------
func _input(event):
	if event is InputEventMouseButton and event.pressed:
		show_next_panel()

# -------------------------------
# show_next_panel(): Animate in next panel
# -------------------------------
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
		tween.tween_property(panel, "position", target_pos, 0.5)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

		# If last panel, wait for click before transitioning
		if current_panel_index + 1 == panels.size():
			await tween.finished
			reminder_label.modulate.a = 1.0
			await wait_for_click()
			reminder_label.modulate.a = 0.0
			get_tree().change_scene_to_file(target_cutscene)

# -------------------------------
# wait_for_click(): Waits for any click input
# -------------------------------
func wait_for_click() -> void:
	while true:
		await get_tree().process_frame
		if Input.is_action_just_pressed("click"):
			break

# -------------------------------
# _process(): Frame update logic
# Handles reminder idle blink + skip logic
# -------------------------------
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

	# Handle blinking reminder animation
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

	# -------------------------------
	# ESC HOLD-TO-SKIP LOGIC
	# -------------------------------
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
# skip_cutscene(): Transition to target level
# -------------------------------
func skip_cutscene():
	get_tree().change_scene_to_file(target_level)
