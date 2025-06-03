extends Control

@onready var label = $Credit
@onready var reminder_label = $Reminder

@export var main_menu_scene: String = "res://Scenes/Mainmenu.tscn"

var blink_speed: float = 2.0
var target_opacity: float = 0.5
var reminder_visible: bool = false
var fade_in_progress: bool = false
var current_opacity: float = 0.0

func _ready():
	# Start fully transparent
	label.modulate.a = 0.0
	reminder_label.modulate.a = 0.0

	# Fade-in credit label
	var tween := create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 3.0)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)

	# After tween finished, start blinking reminder
	await tween.finished

	# Start blinking behavior
	reminder_visible = true
	fade_in_progress = true
	current_opacity = 0.0
	set_process(true)  # Needed for _process to run
	await wait_for_click()

	# Transition to main menu
	get_tree().change_scene_to_file(main_menu_scene)

func wait_for_click() -> void:
	while true:
		await get_tree().process_frame
		if Input.is_action_just_pressed("click") or Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("ui_select"):
			break

func _process(delta: float):
	if reminder_visible:
		if fade_in_progress:
			current_opacity += delta
			var alpha = clamp(current_opacity, 0.0, target_opacity)
			reminder_label.modulate.a = alpha
			if alpha >= target_opacity:
				fade_in_progress = false
		else:
			# Blinking loop (sinusoidal pulse)
			var blink_opacity = 1 + (target_opacity - 1) * (0.5 + 0.5 * sin(blink_speed * Time.get_ticks_msec() / 1000.0))
			reminder_label.modulate.a = blink_opacity
