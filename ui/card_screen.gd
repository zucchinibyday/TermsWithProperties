extends Node2D


func _ready():
	reset_card()

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		reset_card()


func reset_card():
	for child in $CardContainer.get_children():
		$CardContainer.remove_child(child)
	var new_card: Card = Globals.term_set.fill_card()
	$CardContainer.add_child(new_card)
	new_card.clicked.connect(_clicked)


func _clicked(correct: bool):
	if correct:
		reset_card()
