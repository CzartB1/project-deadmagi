class_name UnitActionPanel
extends PanelContainer

@export var action_container: VBoxContainer
@export var target_container: VBoxContainer

@export var unit: Unit
var _selected_action: Action

func _ready() -> void:
	visible=false

func setup(u: Unit):
	unit = u

	action_container.get_parent_control().visible = false
	action_container.get_parent_control().size_flags_vertical=Control.SIZE_SHRINK_BEGIN
	target_container.get_parent_control().visible = false
	target_container.get_parent_control().size_flags_vertical=Control.SIZE_SHRINK_BEGIN
	visible = false

	unit.battle_manager.turn_started.connect(_on_turn_started)
	unit.battle_manager.turn_ended.connect(_on_turn_ended)

	if unit.battle_manager.is_unit_turn(unit):
		_on_turn_started(unit)

# -------------------------------------------------------------------
# Turn handling
# -------------------------------------------------------------------
func _on_turn_started(active_unit: Unit):
	#if active_unit != unit:
		#return

	visible = true
	action_container.get_parent_control().visible = true
	action_container.get_parent_control().size_flags_vertical=Control.SIZE_EXPAND_FILL
	target_container.get_parent_control().visible = false
	refresh()


func _on_turn_ended(active_unit: Unit):
	#if active_unit != unit:
		#return

	visible = false
	action_container.get_parent_control().visible = false
	action_container.get_parent_control().size_flags_vertical=Control.SIZE_SHRINK_BEGIN
	target_container.get_parent_control().visible = false
	target_container.get_parent_control().size_flags_vertical=Control.SIZE_SHRINK_BEGIN


# -------------------------------------------------------------------
# Actions
# -------------------------------------------------------------------
func refresh():
	if unit == null:
		return

	_clear_container(action_container)
	_clear_container(target_container)

	#if not unit.is_ally:
		#return

	var actions := unit.binded_actions if unit.bind_target else unit.actions
	if actions.is_empty():
		return

	for action in actions:
		var btn := Button.new()
		btn.text = action.action_name
		btn.tooltip_text = action.description
		btn.pressed.connect(_on_action_pressed.bind(action))
		action_container.add_child(btn)

	_focus_first_button(action_container)


func _on_action_pressed(action: Action):
	_selected_action = action
	_clear_container(action_container)

	if _action_needs_target(action):
		_setup_targets(action)
	else:
		_execute_action(null)


# -------------------------------------------------------------------
# Targets
# -------------------------------------------------------------------
func _action_needs_target(action: Action) -> bool:
	match action.target:
		Action.action_target.enemies_individual, Action.action_target.allies_individual:
			return true
		_:
			return false


func _setup_targets(action: Action):
	target_container.get_parent_control().visible = true
	target_container.get_parent_control().size_flags_vertical = Control.SIZE_EXPAND_FILL
	action_container.get_parent_control().size_flags_vertical=Control.SIZE_SHRINK_BEGIN
	
	for u in get_tree().get_nodes_in_group("Unit"):
		if not u.alive or u == unit:
			continue

		if action.target == Action.action_target.enemies_individual and u.is_ally == unit.is_ally:
			continue

		if action.target == Action.action_target.allies_individual and u.is_ally != unit.is_ally:
			continue

		var btn := Button.new()
		btn.text = u.unit_name
		btn.pressed.connect(_on_target_pressed.bind(u))
		target_container.add_child(btn)

	var random_btn := Button.new()
	random_btn.text = "Random"
	random_btn.pressed.connect(_on_target_pressed.bind(null))
	target_container.add_child(random_btn)

	_focus_first_button(target_container)


func _on_target_pressed(target: Unit):
	_execute_action(target)


# -------------------------------------------------------------------
# Execution
# -------------------------------------------------------------------
func _execute_action(target: Unit):
	unit.selected_action_index = unit.actions.find(_selected_action)
	unit.forced_target = target
	unit.battle_manager.confirm_turn_button()


# -------------------------------------------------------------------
# Helpers
# -------------------------------------------------------------------
func _clear_container(c: Control):
	for child in c.get_children():
		child.queue_free()


func _focus_first_button(container: Control):
	for child in container.get_children():
		if child is Button and not child.disabled:
			child.grab_focus()
			return
