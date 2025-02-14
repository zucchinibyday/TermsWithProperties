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
	TermSet.updated.connect(_term_set_updated)
	delete_button.pressed.connect(delete_open_set)


func rename_open_set() -> bool:
	if not TermSet.open:
		return false
	AppData.rename_open_set(term_set_name_label.text, TermSet.set_name)
	TermSet.set_name = term_set_name_label.text
	return true

func _load_button_pressed():
	if TermSet.open:
		deconstruct()
	var result := attempt_load(AppData.get_set_data(load_set_text.text))
	if result != LoadResult.OK:
		print(result)
		return
	build()

enum LoadResult { DOES_NOT_EXIST, INVALID_JSON, INVALID_DATA, OK }

func attempt_load(data: Dictionary) -> LoadResult:
	if data == TermSet.get_empty_set_data():
		return LoadResult.DOES_NOT_EXIST
	var result = TermSet.attempt_load(data)
	return LoadResult.OK if result else LoadResult.INVALID_DATA


enum SaveResult { OK, NO_NAME }

func save_open_set() -> SaveResult:
	AppData.save()
	return SaveResult.OK


func create_new_set():
	AppData.save()
	TermSet.unload_term_set()
	deconstruct()
	TermSet.load_empty(create_set_text.text)
	AppData.save()
	build()

func delete_open_set():
	if not TermSet.open:
		return
	AppData.save()
	var set_to_delete = TermSet.set_name
	TermSet.unload_term_set()
	deconstruct()
	AppData.delete_set(set_to_delete)


var rebuild_reasons: Array[TermSet.UpdateReasons] = [
	TermSet.UpdateReasons.TERM_ADDED,
	TermSet.UpdateReasons.TERM_REMOVED,
]

func _term_set_updated(reason: TermSet.UpdateReasons):
	if reason in rebuild_reasons:
		deconstruct()
		build()

func build():
	term_set_name_label.text = TermSet.set_name
	for term: TermSet.Term in TermSet.terms:
		term_item_list.add_child(Globals.term_ui_scene.instantiate().build(term))
	term_adder.build()
	

func deconstruct():
	term_set_name_label.text = ""
	for child in term_item_list.get_children():
		term_item_list.remove_child(child)
	term_adder.deconstruct()

