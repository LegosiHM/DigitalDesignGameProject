extends Node2D

# ------------------------------------------------------------------------------
# DIALOG CONFIGURATION (Inspector Exposed)
# ------------------------------------------------------------------------------
@export var dialog_lines: Array[String] = []  # The lines of dialog to be shown when clicked
@export var dialog_position_Array: Array[Vector2] = []  # Screen positions for each dialog box
@export var cooldown_time: float = 2.0  # Delay before this object can be interacted with again

# ------------------------------------------------------------------------------
# REVEAL OPTIONS (Inspector Exposed)
# ------------------------------------------------------------------------------
@export var will_reveal_object: bool = false  # If true, the object will reveal something after interaction
@export var reveal_panel: Node2D  # Optional: A Node2D that becomes visible after dialog
@export var reveal_path: Area2D  # Optional: A path collider or trigger zone that becomes active

# ------------------------------------------------------------------------------
# RUNTIME NODES (Ready-Time Connections)
# ------------------------------------------------------------------------------
@onready var area = $Area2D  # Area2D for detecting mouse input
@onready var cooldown_timer = Timer.new()  # A custom Timer instance for interaction cooldowns

# ------------------------------------------------------------------------------
# RUNTIME STATE VARIABLES
# ------------------------------------------------------------------------------
var i = 0  # (Unused, possibly for tracking line index?)
var dialog_active: bool = false  # True while dialog is ongoing
var can_interact: bool = true  # Whether player can currently trigger this object
var interacted_once: bool = false  # Whether this interaction already happened once

# ------------------------------------------------------------------------------
# _ready(): Connects signals and sets initial state
# ------------------------------------------------------------------------------
func _ready():
	area.input_event.connect(_on_input_event)  # Connect mouse input for interaction
	add_child(cooldown_timer)  # Add the timer node to scene tree
	cooldown_timer.one_shot = true  # Timer will stop automatically
	cooldown_timer.timeout.connect(_reset_interaction)  # Re-enable interaction after delay

	modulate = Color("333333")  # Default visual (darkened to show unclicked state)

# ------------------------------------------------------------------------------
# _process(delta): Optimized toggle for interaction availability
# ------------------------------------------------------------------------------
func _process(_delta):
	if visible:
		can_interact = true
		set_process(false)  # Disable further processing to save performance
	else:
		can_interact = false

# ------------------------------------------------------------------------------
# _on_input_event(): Triggered when clicked by mouse
# ------------------------------------------------------------------------------
func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		# Do not proceed if already showing dialog
		if !can_interact or dialog_active or DialogManager.is_dialog_active:
			return
		
		modulate = Color("ffffff")  # Change color to show interaction
		_show_dialog()

# ------------------------------------------------------------------------------
# _show_dialog(): Starts dialog interaction through DialogManager
# ------------------------------------------------------------------------------
func _show_dialog():
	dialog_active = true
	can_interact = false  # Prevent re-interaction until dialog ends
	DialogManager.start_dialog(dialog_position_Array, dialog_lines, self)  # External manager handles dialog

# ------------------------------------------------------------------------------
# _on_dialog_finished(): Called by DialogManager when dialog is done
# ------------------------------------------------------------------------------
func _on_dialog_finished():
	cooldown_timer.start(cooldown_time)  # Start cooldown before player can interact again
	dialog_active = false
	interacted_once = true

	# Reveal hidden elements if specified
	if will_reveal_object:
		if reveal_panel != null:
			reveal_panel.visible = true
		if reveal_path != null:
			reveal_path.visible = true

# ------------------------------------------------------------------------------
# _reset_interaction(): Reactivates interaction after cooldown ends
# ------------------------------------------------------------------------------
func _reset_interaction():
	can_interact = true
