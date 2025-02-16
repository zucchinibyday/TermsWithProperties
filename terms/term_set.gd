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
	unsaved_changes = true
	updated.emit(UpdateReasons.TERM_ADDED)

func delete_term(term: Term) -> bool:
	var term_index = terms.find(term)
	if term_index == -1:
		return false
	terms.remove_at(term_index)
	updated.emit(UpdateReasons.TERM_REMOVED)
	return true

func dummy_term(dummy_name := "Dummy") -> TermSet.Term:
	var props: Array[TermProperty] = []
	for group in property_groups:
		props.append(TermProperty.new(group, ""))
	var dummy := Term.new(dummy_name, props)
	dummy.dummy = true
	return dummy

func has_term(term_name: String) -> bool:
	for term in terms:
		if term.name == term_name:
			return true
	return false


# Property groups automatically check for repeated values
func add_to_prop_group(property: TermProperty, term: Term = null):
	if not property.group in property_groups:
		property_groups[property.group] = PropertyGroup.new()
	property_groups[property.group].add_value(property.value, term)

func remove_from_prop_group(property: TermProperty, term: Term = null):
	if not property.group in property_groups:
		return
	property_groups[property.group].remove_term_from_value(property.value, term)

func update_prop_group(property: TermProperty, old_value, term: Term):
	var prop_group: PropertyGroup
	if not property.group in property_groups:
		prop_group = PropertyGroup.new()
	prop_group = property_groups[property.group]
	prop_group.remove_term_from_value(old_value, term)
	prop_group.add_value(property.value, term)


# deprecated
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
	# dummy terms do not update the termset whatsoever
	var dummy := false
	var _copy_counter := 0
	# properties = <prop name>: { value: <prop value>, group: <property group> }
	var properties: Array[TermProperty]
	
	func _init(_name: String, _properties: Array[TermProperty]):
		name = _name
		properties = _properties
		for property in properties:
			TermSet.add_to_prop_group(property, self)
	
	func add_property(new_property: TermProperty, notify := true) -> bool:
		if new_property in properties:
			return false
		for prop in properties:
			if prop.group == new_property.group:
				return false
		properties.append(new_property)
		if dummy:
			return true
		TermSet.add_to_prop_group(new_property, self)
		if notify:
			TermSet.updated.emit(UpdateReasons.PROPERTY_ADDED)
		return true

	func random_property() -> TermProperty:
		var i = floor(randf() * len(self.properties))
		return self.properties[i]
	
	func update_property(group: String, new_value) -> bool:
		for prop in properties:
			if prop.group == group:
				var old_value = prop.value
				prop.value = new_value
				if dummy:
					return true
				TermSet.update_prop_group(prop, old_value, self)
				TermSet.updated.emit(UpdateReasons.TERM_UPDATED)
				return true
		return false
	
	func delete_property(group: String) -> bool:
		print("try delete")
		var prop
		for i in range(len(properties)):
			prop = properties[i]
			if prop.group == group:
				TermSet.remove_from_prop_group(prop, self)
				properties.remove_at(i)
				print("deleted")
				return true
		print("not found")
		return false
	
	func duplicate(new_name := "", new_is_dummy := false) -> Term:
		if new_name == "":
			if dummy:
				new_name = name
			else:
				_copy_counter += 1
				new_name = "%s%s" % [name, _copy_counter]
		var new_term: Term
		if new_is_dummy:
			new_term = Term.new(new_name, [] as Array[TermProperty])
			new_term.dummy = dummy
			new_term.properties = properties
		else:
			new_term = Term.new(name, properties)
		return new_term

	func save() -> Dictionary:
		var data = {
			"name": name,
			"properties": []
		}
		for property in properties:
			data["properties"].append(property.save())
		return data
	
	func delete():
		if dummy:
			return
		TermSet.delete_term(self)


class PropertyGroup:
	# possible_values = { <value>: <list of terms with this value>, ... }
	var _possible_values: Dictionary
	
	func add_value(value, term: Term = null):
		if not value in _possible_values:
			_possible_values[value] = []
		if term:
			_possible_values[value].append(term)
	
	func has_value(value) -> bool:
		return value in _possible_values
	
	func get_possible_values() -> Array:
		var final: Array = []
		for pv in _possible_values:
			if len(_possible_values[pv]) > 0:
				final.append(pv)
		return final
	
	func get_terms_with_value(value) -> Array:
		if not has_value(value):
			return []
		return _possible_values[value]

	func remove_value(value) -> bool:
		if not value in _possible_values:
			return false
		_possible_values.erase(value)
		return true

	func remove_term_from_value(value, term: Term) -> bool:
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
	var is_boolean := false
	var group: String
	var value
	
	func _init(_group, _value, _is_boolean := false):
		group = _group
		value = _value
		is_boolean = _is_boolean
		
	func save() -> Dictionary:
		var r := {
			"group": group,
			"value": value
		}
		if is_boolean:
			r["is_boolean"] = true
		return r
