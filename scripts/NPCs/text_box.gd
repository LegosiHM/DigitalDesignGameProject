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
	label.text = ""  # ✅ Ensure previous text is cleared
	letter_index = 0  # ✅ Reset letter index
	DialogManager.can_advance_line = false
	
	label.autowrap_mode = TextServer.AUTOWRAP_WORD  # ✅ Enable word wrapping
	label.custom_minimum_size.x = MAX_WIDTH  # ✅ Limit max width
	
	_display_letter()  # Start displaying text letter-by-letter


func _display_letter():
	if letter_index >= text.length():
		finished_displaying.emit()  # ✅ Ensure text animation completes properly
		return
	
	# ✅ Fix: Instead of appending, slice the text to display only correct part
	label.text = text.substr(0, letter_index + 1)
	
	letter_index += 1
	
	if label.text == text:
		timer.stop()
		finished_displaying.emit()
		return 
	
	match text[letter_index - 1]:
		"!", ".", ",", "?":
			timer.start(punctuation_time)
		" ":
			timer.start(space_time)
		_:
			timer.start(letter_time)


func _on_letter_display_timer_timeout():
	_display_letter()  # Continue showing the next letter
