extends HBoxContainer
class_name PropertyUI


signal value_changed
signal changes_confirmed

var group: String:
	set(new_val):
		$RichTextLabel.text = new_val
		group = new_val
	get:
		return $RichTextLabel.text

var value: String:
	set(new_val):
		$TextEdit.text = new_val
		value = new_val
	get:
		return $TextEdit.text


func _ready():
	$TextEdit.text_changed.connect(func(): value_changed.emit(self))
	$ConfirmButton.pressed.connect(func(): changes_confirmed.emit(self))

func build(property: TermSet.TermProperty) -> PropertyUI:
	group = property.group
	value = property.value
	return self

func build_raw(_group: String, _value := "") -> PropertyUI:
	group = _group
	value = _value
	return self
