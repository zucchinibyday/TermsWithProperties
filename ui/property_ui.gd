extends HBoxContainer
class_name PropertyUI


signal value_changed
signal changes_confirmed
signal delete_property

@export var group_editable := false
@export var deletable := true

var group: String:
	set(new_val):
		$GroupText.text = new_val
		group = new_val
	get:
		return $GroupText.text

var value:
	set(new_val):
		$ValueText.text = new_val
		value = new_val
	get:
		return $ValueText.text

var property: TermSet.TermProperty:
	get:
		return TermSet.TermProperty.new(group, value)


func _ready():
	$GroupText.text_changed.connect(func(): value_changed.emit(self))
	$GroupText.focus_exited.connect(update_property)
	$ValueText.text_changed.connect(func(): value_changed.emit(self))
	$ValueText.focus_exited.connect(update_property)
	$ConfirmButton.pressed.connect(update_property)
	$DeleteButton.pressed.connect(func(): 
		if deletable:
			delete_property.emit(self)
	)

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
