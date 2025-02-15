@tool
extends Panel

func _process(delta: float):
	custom_minimum_size.y = $Header/TermName.size.y
