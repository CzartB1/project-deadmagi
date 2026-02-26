class_name ActionManager
extends Node

var unit: Unit

var base_actions: Array[Action] = []
var base_bind_actions: Array[Action] = []

var total_actions: Array[Action] = []
var total_bind_actions: Array[Action] = []

var seen := {}

func setup(u: Unit):
	unit = u
	base_actions = u.actions.duplicate()
	base_bind_actions = u.binded_actions.duplicate()
	rebuild_from_items()

func rebuild_from_items():
	seen.clear()

	total_actions.clear()
	total_bind_actions.clear()

	for a in base_actions:
		add_unique(a, total_actions)

	for a in base_bind_actions:
		add_unique(a, total_bind_actions)

	for item in unit.equipped_items:
		if item == null:
			continue

		for scene in item.granted_actions:
			add_unique(scene.instantiate(), total_actions)

		for scene in item.granted_bind_actions:
			add_unique(scene.instantiate(), total_bind_actions)

	unit.actions = total_actions.duplicate()
	unit.binded_actions = total_bind_actions.duplicate()
	unit.update_action.emit()

func add_unique(action: Action, target: Array):
	var key := action.get_instance_id()
	if seen.has(key):
		return
	seen[key] = true
	target.append(action)
