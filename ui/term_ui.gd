extends VBoxContainer
class_name TermUI


var term: TermSet.Term

@export var header: HBoxContainer
@export var delete_button: Button
@export var prop_container: VBoxContainer
@export var add_prop_button: Button
@export var new_prop_ui: PropertyUI

var property_items: Array[RichTextLabel]


func _ready():
	delete_button.pressed.connect(delete_term)
	add_prop_button.pressed.connect(add_new_property)


func build(_term: TermSet.Term):
	term = _term
	header.get_node("TermName").text = "[center]%s" % term.name
	for property: TermSet.TermProperty in term.properties:
		var new_prop: PropertyUI = Globals.prop_ui_scene.instantiate().build(property)
		new_prop.changes_confirmed.connect(_prop_value_changed)
		prop_container.add_child(new_prop)
	return self

func _prop_value_changed(prop: PropertyUI):
	term.update_property(prop.group, prop.value)

func delete_term():
	term.delete()

func add_new_property():
	print("Button pressed; add new property %s %s" % [new_prop_ui.group, new_prop_ui.value])
	term.add_property(new_prop_ui.group, new_prop_ui.value)
