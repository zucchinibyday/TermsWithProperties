extends Node


var prop_ui_scene := preload("res://ui/property_ui.tscn")
var term_ui_scene := preload("res://ui/term_ui.tscn")

var debug: int = 0
enum DebugFlags { ALWAYS_LOAD_DEFAULT = 1, ALLOW_RESET_META = 2 }


func _init():
	debug |= DebugFlags.ALLOW_RESET_META
