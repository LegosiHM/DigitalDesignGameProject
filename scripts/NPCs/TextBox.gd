extends Control

# ------------------------------------------------------------------------------
# NODE REFERENCES
# ------------------------------------------------------------------------------

@onready var label = $MarginContainer/Label  # Displays the text
@onready var timer = $LetterDisplayTimer     # Controls the pacing of character display

# ------------------------------------------------------------------------------
# CONFIGURABLE CONSTANTS
# ------------------------------------------------------------------------------

const MAX_WIDTH: int = 256  # Maximum width of the label before wrapping

# Display delays based on character type
const LETTER_TIME: float = 0.03       # Time delay between regular characters
const SPACE_TIME: float = 0.06        # Time delay after a space
const PUNCTUATION_TIME: float = 0.2   # Longer pause after punctuation

# ------------------------------------------------------------------------------
# INTERNAL STATE VARIABLES
# ------------------------------------------------------------------------------

var text: String = ""        # Full text to display
var letter_index: int = 0    # Current letter index to display

# ------------------------------------------------------------------------------
# SIGNALS
# ------------------------------------------------------------------------------

signal finished_displaying()  # Emitted when all text has been shown

# ------------------------------------------------------------------------------
# DISPLAY ENTRY POINT
# ------------------------------------------------------------------------------

# Starts displaying the text one letter at a time
func display_text(text_to_display: String):
	text = text_to_display          # Store full input text
	label.text = ""                # Clear label before displaying
	letter_index = 0               # Reset index to start from beginning

	# Set label properties
	label.autowrap_mode = TextServer.AUTOWRAP_WORD  # Enable word wrap
	label.custom_minimum_size.x = MAX_WIDTH         # Set label width

	_display_letter()  # Begin displaying characters

# ------------------------------------------------------------------------------
# INTERNAL DISPLAY HANDLER
# ------------------------------------------------------------------------------

# Handles one character reveal and schedules next using the timer
func _display_letter():
	# If we've shown all letters, emit finished signal
	if letter_index >= text.length():
		finished_displaying.emit()
		return

	# Show current slice of text
	label.text = text.substr(0, letter_index + 1)
	letter_index += 1

	# If this was the final letter (backup check), stop
	if label.text == text:
		timer.stop()
		finished_displaying.emit()
		return

	# Determine pause duration based on character type
	match text[letter_index - 1]:
		"!", ".", ",", "?":
			timer.start(PUNCTUATION_TIME)
		" ":
			timer.start(SPACE_TIME)
		_:
			timer.start(LETTER_TIME)

# ------------------------------------------------------------------------------
# TIMER CALLBACK
# ------------------------------------------------------------------------------

# Called when the timer finishes — triggers the next letter display
func _on_letter_display_timer_timeout():
	_display_letter()
