extends VBoxContainer
class_name TermUI


var prev_editable := true
@export var editable := true
@export var term_name_editable := true
@export var deletable := true
@export var duplicable := true

@export var dummy := false
var term: TermSet.Term

@export var header: HBoxContainer
@export var term_name_text: TextEdit
@export var delete_button: Button
@export var prop_container: VBoxContainer
@export var add_prop_button: Button
@export var new_prop_ui: PropertyUI


signal deleted
signal duplicated
signal property_added


func _ready():
	delete_button.pressed.connect(delete_term)
	add_prop_button.pressed.connect(add_new_property)
	term_name_text.text_changed.connect(_term_name_changed)
	$Header/DuplicateButton.pressed.connect(duplicate_term)

func _process(delta: float):
	if editable != prev_editable:
		prev_editable = editable
		$PropAdder.visible = editable
		# If the term becomes editable again, the textedits controlling group names
		# in prop ui nodes will be set accordingly by their own script; 
		# no need to worry about accidentally making editable that which should not be
		set_text_edits_editable(self, editable)
	term_name_text.editable = term_name_editable
	$Header/DeleteButton.visible = deletable

# Recursively searches a tree for text edits and enables or disables them
func set_text_edits_editable(node: Node, editable: bool):
	if len(node.get_children()) == 0:
		return
	for child in node.get_children():
		set_text_edits_editable(child, editable)
		if child is TextEdit:
			child.editable = editable


func build(_term: TermSet.Term):
	term = _term
	term_name_text.text = "%s" % term.name
	for property: TermSet.TermProperty in term.properties:
		var new_prop: PropertyUI = Globals.prop_ui_scene.instantiate().build(property)
		new_prop.changes_confirmed.connect(_prop_value_changed)
		new_prop.delete_property.connect(delete_property)
		prop_container.add_child(new_prop)
	return self

func deconstruct():
	term = null
	term_name_text.text = ""
	for child in prop_container.get_children():
		prop_container.remove_child(child)

func rebuild():
	var old_term = term
	deconstruct()
	build(old_term)


func _prop_value_changed(prop: PropertyUI):
	if not term:
		return
	if editable:
		term.update_property(prop.group, prop.value)
	rebuild()

func _term_name_changed():
	if not term:
		return
	term.name = term_name_text.text

func delete_term():
	if not editable or not deletable or not term:
		return
	deleted.emit()
	term.delete()

func duplicate_term():
	if not editable or not duplicable or not term:
		return
	TermSet.add_new_term("Copy of %s" % term.name, term.properties)
	duplicated.emit()

func add_new_property():
	if not editable or not term:
		return
	var new_prop = TermSet.TermProperty.new(new_prop_ui.group, new_prop_ui.value)
	term.add_property(new_prop)
	property_added.emit(new_prop)
	rebuild()

func delete_property(prop_ui: PropertyUI):
	term.delete_property(prop_ui.group)
	prop_ui.queue_free()
