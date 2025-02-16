extends Node


@export var default_screen: PackedScene
var current_screen: Node2D


func _ready():
	current_screen = default_screen.instantiate()
	add_child(current_screen)


func _process(delta: float):
	if Input.is_action_just_pressed("reload_ui"):
		print("Rebuild")
		current_screen.deconstruct()
		current_screen.build()
