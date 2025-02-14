@tool
extends Control
class_name Card


var term: TermSet.Term
var property_name: String
var options: Dictionary


@export var answer_scene: PackedScene


@export var target_size: Vector2 = 0.9 * Vector2(
		ProjectSettings.get_setting("display/window/size/viewport_width"), 
		ProjectSettings.get_setting("display/window/size/viewport_height")
	)


func build(_term, property, answers):
	term = _term
	self.property_name = property.name
	set_question_text(term.term_name, property_name)
	for i in range(len(answers)):
		var option = {}
		option["correct"] = i == 0
		option["text"] = answers[i]
		while len(self.options.keys()) < i + 1:
			var j = int(floor(randf() * 4))
			if not j in self.options.keys():
				self.options[j] = option
				var answer_node = answer_scene.instantiate()
	for i in range(4):
		var correct = options[i]["correct"]
		var text = options[i]["text"]
		var answer_node: CardAnswer = answer_scene.instantiate().build(text, correct)
		answer_node.clicked.connect(_clicked)
		$VBoxContainer/AnswersGrid.add_child(answer_node)
	return self


func set_question_text(term_text, property_text):
	var label = $VBoxContainer/QuestionContainer/Text
	label.text = "What is the %s of %s?" % [property_text, term_text]


func _process(_delta: float) -> void:
	size = target_size
	$VBoxContainer.size = target_size
	$Panel.size = target_size
	

signal clicked


func _clicked(answer: CardAnswer):
	clicked.emit(answer.correct)
