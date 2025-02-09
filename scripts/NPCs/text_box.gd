extends Control

@onready var label = $MarginContainer/Label
@onready var timer = $LetterDisplayTimer

const MAX_WIDTH = 256

var text = ""
var letter_index = 0

var letter_time = 0.03
var space_time = 0.06
var punctuation_time = 0.2

signal finished_displaying()

func display_text(text_to_display: String):
	text = text_to_display
	label.text = ""  # Clear previous text
	letter_index = 0  # Reset letter index
	
	label.autowrap_mode = TextServer.AUTOWRAP_WORD  # ✅ Ensure text wraps properly
	label.custom_minimum_size.x = min(size.x, MAX_WIDTH)  # ✅ Set max width constraint
	
	_display_letter()  # Start displaying text one letter at a time


func _display_letter():
	if letter_index >= text.length():
		finished_displaying.emit()  # Notify that the text is done displaying
		return

	label.text += text[letter_index]  # Add the next letter
	letter_index += 1

	# Adjust timing based on character type
	match text[letter_index - 1]:
		"!", ".", ",", "?":
			timer.start(punctuation_time)
		" ":
			timer.start(space_time)
		_:
			timer.start(letter_time)

func _on_letter_display_timer_timeout():
	_display_letter()  # Continue showing the next letter
