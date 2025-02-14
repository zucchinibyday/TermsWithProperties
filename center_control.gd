@tool
extends Control
class_name CenterControl


func _process(delta: float) -> void:
	for child in get_children():
		if not child is Control: continue
		child.position = (size * 0.5) - (child.size * 0.5)
