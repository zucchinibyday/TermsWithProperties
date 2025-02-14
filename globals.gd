extends Node


var term_set: TermSet

var app_data := AppData.new()

var prop_ui_scene := preload("res://ui/property_ui.tscn")
var term_ui_scene := preload("res://ui/term_ui.tscn")

var debug: int = 0
enum DebugFlags { ALWAYS_LOAD_DEFAULT = 1 }


func _ready() -> void:
	debug |= DebugFlags.ALWAYS_LOAD_DEFAULT
	term_set = TermSet.new()


"""
format of metadata:
	{
		"sets": [
			{
				"name": <name of set>,
				"data": <set data>
			} ...
		]
	}
"""
class AppData:
	var _saved_sets := {}
	
	func _init() -> void:
		"""var metafile = FileAccess.open(
				meta_path() if DirAccess.dir_exists_absolute(meta_path()) 
					else default_meta_path(),
				FileAccess.READ
		)"""
		var metafile = FileAccess.open(default_meta_path(), FileAccess.READ)
		var data: Dictionary = JSON.parse_string(metafile.get_as_text())
		for _set in data["sets"]:
			_saved_sets[_set["name"]] = _set
	
	func app_dir():
		return "res://terms/"
	
	func meta_path():
		return "%smeta.json" % app_dir()
	
	func default_meta_path():
		return "res://default_app_data.json"
	
	func get_set_data(term_set_name: String) -> Dictionary:
		if not term_set_name in _saved_sets:
			return TermSet.get_empty_set_data()
		return _saved_sets[term_set_name]
	
	func rename_open_set(new_name: String, old_name: String):
		_saved_sets[new_name] = _saved_sets[old_name]
		_saved_sets.erase(old_name)
	
	func delete_set(set_name: String):
		if not set_name in _saved_sets:
			return
		_saved_sets.erase(set_name)
		save()

	func save():
		# First save the data for the currently opened set
		if Globals.term_set.open:
			_saved_sets[Globals.term_set.set_name] = Globals.term_set.save()
		# Pack set data
		var new_data := { "sets" = [] }
		for saved_set_name in _saved_sets.keys():
			var saved_set = _saved_sets[saved_set_name]
			new_data["sets"].append(saved_set)
		# Write to file
		DirAccess.open(app_dir()).remove(meta_path())
		var metafile = FileAccess.open(meta_path(), FileAccess.WRITE)
		metafile.store_string(JSON.stringify(new_data))
		
