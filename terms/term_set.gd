extends Node


var open := false
var unsaved_changes = true
var set_name: String
var terms: Array[Term]
var property_groups: Dictionary

enum UpdateReasons { UNLOAD, LOAD, TERM_ADDED, TERM_REMOVED, TERM_UPDATED, PROPERTY_ADDED }
signal updated

@onready var card_scene := load("res://card/card.tscn")


func _ready():
	updated.connect(func(reason): unsaved_changes = true)


func attempt_load(data: Dictionary) -> bool:
	if open:
		unload_term_set()
	return load_term_set(data)

func unload_term_set():
	if unsaved_changes:
		AppData.save()
	terms = []
	property_groups = {}
	open = false
	updated.emit(UpdateReasons.UNLOAD)

# TODO handle bad data
func load_term_set(data: Dictionary) -> bool:
	if open:
		return false
	set_name = data["name"]
	open = true
	for raw_term in data["terms"]:
		var properties: Array[TermProperty] = []
		for raw_property in raw_term["properties"]:
			var property = TermProperty.new(raw_property["group"], raw_property["value"])
			properties.append(property)
		var new_term = Term.new(raw_term["name"], properties)
		terms.append(new_term)
	updated.emit(UpdateReasons.LOAD)
	return true

func load_empty(new_name := "Empty set") -> bool:
	if open:
		return false
	load_term_set(TermSet.get_empty_set_data(new_name))
	return true

# Packs the set into a string
# TODO caching property groups
func save() -> Dictionary:
	var data = { "name": set_name, "terms": [] }
	for term: Term in terms:
		data["terms"].append(term.save())
	unsaved_changes = false
	return data

func get_empty_set_data(new_name := "Empty set") -> Dictionary:
	return {
		"name": new_name,
		"terms": []
	}


# Adds a new term to the term set after loading
# If a term already exists, automatically updates the term
# Else creates the new term
func add_new_term(term_name: String, properties: Array[TermProperty]):
	for term in terms:
		if term_name == term.name:
			for prop in properties:
				term.update_property(prop.group, prop.value)
			return
	var new_term = Term.new(term_name, properties)
	terms.append(new_term)
	updated.emit(UpdateReasons.TERM_ADDED)

func delete_term(term: Term) -> bool:
	var term_index = terms.find(term)
	if term_index == -1:
		print("term was not found")
		return false
	terms.remove_at(term_index)
	updated.emit(UpdateReasons.TERM_REMOVED)
	return true


func add_to_prop_group(property: TermProperty, term):
	if not property.group in property_groups:
		property_groups[property.group] = PropertyGroup.new()
	property_groups[property.group].add_value(property.value, term)

func update_prop_group(property: TermProperty, old_value: String, term: Term):
	var prop_group: PropertyGroup
	if not property.group in property_groups:
		prop_group = PropertyGroup.new()
	prop_group = property_groups[property.group]
	prop_group.remove_term_from_value(old_value, term)
	prop_group.add_value(property.value, term)


func fill_card() -> Card:
	var i = floor(randf() * len(terms))
	var random_term := terms[i]
	var random_property = random_term.random_property()
	var prop_group: PropertyGroup = property_groups[random_property["group"]]
	var answers: Array[String] = [random_property.value]
	while len(answers) < 4:
		i = floor(randf() * len(prop_group.possible_values.keys()))
		if not prop_group.possible_values.keys()[i] in answers:
			answers.append(prop_group.possible_values.keys()[i])
	var card = card_scene.instantiate().build(random_term, random_property, answers)
	return card


class Term:
	var name: String
	# properties = <prop name>: { value: <prop value>, group: <property group> }
	var properties: Array[TermProperty]
	
	func _init(_name: String, _properties: Array[TermProperty]):
		name = _name
		properties = _properties
		for property in properties:
			TermSet.add_to_prop_group(property, self)
	
	func add_property(group: String, value: String) -> bool:
		for prop in properties:
			if prop.group == group:
				print("this prop already exists, do not add")
				return false
		var prop = TermProperty.new(group, value)
		properties.append(prop)
		TermSet.add_to_prop_group(prop, self)
		print("this prop did not already exists, add")
		TermSet.updated.emit(UpdateReasons.PROPERTY_ADDED)
		return true


	func random_property() -> TermProperty:
		var i = floor(randf() * len(self.properties))
		return self.properties[i]
	
	func update_property(group: String, new_value: String) -> bool:
		for prop in properties:
			if prop.group == group:
				var old_value = prop.value
				prop.value = new_value
				TermSet.update_prop_group(prop, old_value, self)
				TermSet.updated.emit(UpdateReasons.TERM_UPDATED)
				return true
		return false
		
	func save() -> Dictionary:
		var data = {
			"name": name,
			"properties": []
		}
		for property in properties:
			data["properties"].append(property.save())
		return data
	
	func delete():
		TermSet.delete_term(self)
		print("delete")


class PropertyGroup:
	# possible_values = { <value>: <list of terms with this value>, ... }
	var _possible_values: Dictionary
	
	func add_value(value: String, term: Term):
		if not value in _possible_values:
			_possible_values[value] = [term]
			return true
		if term in _possible_values[value]:
			return false
		_possible_values[value].append(term)
		return true
	
	func has_value(value: String) -> bool:
		return value in _possible_values
	
	func get_possible_values() -> Array[String]:
		var final: Array[String] = []
		for pv in _possible_values:
			if len(_possible_values[pv]) > 0:
				final.append(pv)
		return final
	
	func get_terms_with_value(value: String) -> Array:
		if not has_value(value):
			return []
		return _possible_values[value]

	func remove_value(value: String) -> bool:
		if not value in _possible_values:
			return false
		_possible_values.erase(value)
		return true

	func remove_term_from_value(value: String, term: Term) -> bool:
		if not value in _possible_values:
			return false
		if not term in _possible_values[value]:
			return false
		var i = _possible_values[value].find(term)
		_possible_values[value].remove_at(i)
		if len(_possible_values[value]) == 0:
			_possible_values.erase(value)
		return true


class TermProperty:
	var value
	var group
	
	func _init(_group, _value):
		group = _group
		value = _value
		
	func save() -> Dictionary:
		return {
			"group": group,
			"value": value
		}
