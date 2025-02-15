extends HBoxContainer
class_name PropertyUI


signal value_changed
signal changes_confirmed

@export var group_editable := false

var group: String:
	set(new_val):
		$GroupText.text = new_val
		group = new_val
	get:
		return $GroupText.text

var value: String:
	set(new_val):
		$ValueText.text = new_val
		value = new_val
	get:
		return $ValueText.text


func _ready():
	$ValueText.text_changed.connect(func(): value_changed.emit(self))
	$ConfirmButton.pressed.connect(update_property)
	$ValueText.focus_exited.connect(update_property)

func _process(delta: float):
	$GroupText.editable = group_editable

func update_property():
	changes_confirmed.emit(self)

func build(property: TermSet.TermProperty) -> PropertyUI:
	group = property.group
	value = property.value
	return self

func build_raw(_group: String, _value := "") -> PropertyUI:
	group = _group
	value = _value
	return self
