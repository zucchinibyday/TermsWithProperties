extends VBoxContainer
class_name TermAdder


# The term ui the user can use to write a new term
@export var dummy_term_ui: TermUI
var dummy_term: TermSet.Term
@export var button: Button


func _ready():
	dummy_term_ui.property_added.connect(property_added)
	button.pressed.connect(add_term)


func build(new_dummy := TermSet.dummy_term()) -> TermAdder:
	dummy_term = new_dummy
	dummy_term_ui.build(dummy_term)
	dummy_term_ui.term_name_editable = true
	return self

func deconstruct():
	dummy_term_ui.deconstruct()


func property_added(new_property):
	TermSet.add_to_prop_group(new_property, null)
	deconstruct()
	build(dummy_term)


func add_term():
	if not TermSet.open:
		return
	TermSet.add_new_term(dummy_term.name, dummy_term.properties)
	AppData.save()
