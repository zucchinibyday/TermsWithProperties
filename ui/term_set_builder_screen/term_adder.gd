extends VBoxContainer
class_name TermAdder


func _ready():
	$HBoxContainer/Button.pressed.connect(add_term)


func build() -> TermAdder:
	for prop_group: String in Globals.term_set.property_groups.keys():
		$PropertyContainer.add_child(Globals.prop_ui_scene.instantiate().build_raw(prop_group))
	return self

func deconstruct():
	for prop in $PropertyContainer.get_children():
		prop.queue_free()
	$HBoxContainer/TextEdit.text = ""


func add_term():
	var props: Array[TermSet.TermProperty]
	for prop_ui in $PropertyContainer.get_children():
		props.append(TermSet.TermProperty.new(prop_ui.group, prop_ui.value))
	Globals.term_set.add_new_term($HBoxContainer/TextEdit.text, props)
