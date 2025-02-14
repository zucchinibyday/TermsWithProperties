extends Node2D


@export var term_set_name_label: TextEdit
@export var term_item_list: VBoxContainer
@export var load_set_button: Button
@export var load_set_text: TextEdit
@export var save_set_button: Button
@export var term_adder: TermAdder
@export var create_set_button: Button
@export var create_set_text: TextEdit
@export var delete_button: Button


func _ready() -> void:
	term_set_name_label.text_changed.connect(rename_open_set)
	load_set_button.pressed.connect(_load_button_pressed)
	save_set_button.pressed.connect(save_open_set)
	create_set_button.pressed.connect(create_new_set)
	Globals.term_set.updated.connect(_term_set_updated)
	delete_button.pressed.connect(delete_open_set)


func rename_open_set() -> bool:
	if not Globals.term_set.open:
		return false
	Globals.app_data.rename_open_set(term_set_name_label.text, Globals.term_set.set_name)
	Globals.term_set.set_name = term_set_name_label.text
	return true

func _load_button_pressed():
	if Globals.term_set.open:
		deconstruct()
	var result := attempt_load(Globals.app_data.get_set_data(load_set_text.text))
	if result != LoadResult.OK:
		print(result)
		return
	build()

enum LoadResult { DOES_NOT_EXIST, INVALID_JSON, INVALID_DATA, OK }

func attempt_load(data: Dictionary) -> LoadResult:
	if data == TermSet.get_empty_set_data():
		return LoadResult.DOES_NOT_EXIST
	var result = Globals.term_set.attempt_load(data)
	return LoadResult.OK if result else LoadResult.INVALID_DATA


enum SaveResult { OK, NO_NAME }

func save_open_set() -> SaveResult:
	Globals.app_data.save()
	return SaveResult.OK


func create_new_set():
	Globals.app_data.save()
	Globals.term_set.unload_term_set()
	deconstruct()
	Globals.term_set.load_empty(create_set_text.text)
	build()

func delete_open_set():
	if not Globals.term_set.open:
		return
	Globals.app_data.save()
	var set_to_delete = Globals.term_set.set_name
	Globals.term_set.unload_term_set()
	deconstruct()
	Globals.app_data.delete_set(set_to_delete)


var rebuild_reasons: Array[TermSet.UpdateReasons] = [
	TermSet.UpdateReasons.TERM_ADDED,
	TermSet.UpdateReasons.TERM_REMOVED,
]

func _term_set_updated(reason: TermSet.UpdateReasons):
	if reason in rebuild_reasons:
		deconstruct()
		build()

func build():
	term_set_name_label.text = Globals.term_set.set_name
	for term: TermSet.Term in Globals.term_set.terms:
		term_item_list.add_child(Globals.term_ui_scene.instantiate().build(term))
	term_adder.build()
	

func deconstruct():
	term_set_name_label.text = ""
	for child in term_item_list.get_children():
		term_item_list.remove_child(child)
	term_adder.deconstruct()

