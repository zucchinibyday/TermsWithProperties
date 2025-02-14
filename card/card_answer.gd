@tool
extends MarginContainer
class_name CardAnswer


signal clicked
var correct = false

var text: String:
	set(new_text):
		text = new_text
		$Text.text = new_text
	get:
		return $Text.get_parsed_text()

func _ready():
	$Button.connect("button_up", _button_up)

func build(_text: String, _correct: bool):
	text = _text
	correct = _correct
	if correct:
		modulate = Color.GREEN
	return self

func _button_up():
	print(correct)
	clicked.emit(self)
