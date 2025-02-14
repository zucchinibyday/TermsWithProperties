extends Node


var prop_ui_scene := preload("res://ui/property_ui.tscn")
var term_ui_scene := preload("res://ui/term_ui.tscn")

var debug: int = 0
enum DebugFlags { ALWAYS_LOAD_DEFAULT = 1 }


func _ready() -> void:
	debug |= DebugFlags.ALWAYS_LOAD_DEFAULT
