extends VBoxContainer
class_name TermUI


var term: TermSet.Term

@onready var header := $Header

var property_items: Array[RichTextLabel]


func _ready():
	$Header/DeleteButton.pressed.connect(delete_term)


func build(_term: TermSet.Term):
	term = _term
	$Header/TermName.text = "[center]%s" % term.name
	for property: TermSet.TermProperty in term.properties:
		var new_prop: PropertyUI = Globals.prop_ui_scene.instantiate().build(property)
		new_prop.changes_confirmed.connect(_prop_value_changed)
		add_child(new_prop)
	return self

func _prop_value_changed(prop: PropertyUI):
	term.update_property(prop.group, prop.value)

func delete_term():
	term.delete()
