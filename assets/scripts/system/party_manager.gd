class_name PartyManager
extends Control

## =========================
## CONSTANTS
## =========================

const MAX_STAT_GAINS := 5

## =========================
## EXPORTS
## =========================

@export var formation_line: FormationLine3D

## The TabContainer that holds one UnitPanel per party member.
@export var tab_container: TabContainer

## The HBoxContainer that holds the draggable formation cards.
@export var formation_row: HBoxContainer

## Scene to instantiate for each unit's panel tab.
@export var unit_panel_scene: PackedScene

## Scene to instantiate for each formation card.
@export var formation_card_scene: PackedScene

## When true, the last selected tab is remembered between menu opens.
## Hook this up to a settings toggle at your leisure.
var persist_selected_tab: bool = false

## =========================
## RUNTIME STATE
## =========================

## Canonical ordered roster. Formation and turn order derive from this array.
var party: Array[Unit] = []

var _last_selected_tab: int = 0
var _is_open: bool = false

## =========================
## SIGNALS
## =========================

signal party_changed
signal menu_opened
signal menu_closed
signal stat_growth_changed(unit: Unit)

## =========================
## LIFECYCLE
## =========================

func _ready() -> void:
	if tab_container:
		tab_container.tab_changed.connect(_on_tab_changed)
	close_menu()

func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("party_menu_toggle"):
		if _is_open:close_menu()
		else:open_menu()

## =========================
## UNIT REGISTRATION
## =========================

## Primary entry point for adding a unit to the party.
## Call this from any script that spawns or recruits a unit:
##   party_manager.register_unit(my_unit)
func register_unit(unit: Unit) -> void:
	if unit == null:
		push_error("PartyManager: register_unit() called with null unit.")
		return
	if unit in party:
		push_warning("PartyManager: Unit '%s' is already registered." % unit.unit_name)
		return

	party.append(unit)
	unit.died.connect(_on_unit_died.bind(unit))

	_sync_formation_line()

	# If the menu is currently open, rebuild immediately so the new unit appears.
	if _is_open:
		_rebuild_tabs()
		_rebuild_formation_row()

	party_changed.emit()
	print("[PartyManager] Registered: %s (party size: %d)" % [unit.unit_name, party.size()])


## Remove a unit from the party manually (e.g. unit leaves, not dies).
func unregister_unit(unit: Unit) -> void:
	if unit not in party:
		return

	party.erase(unit)

	if unit.died.is_connected(_on_unit_died):
		unit.died.disconnect(_on_unit_died)

	_sync_formation_line()

	if _is_open:
		_rebuild_tabs()
		_rebuild_formation_row()

	party_changed.emit()


func _on_unit_died(unit: Unit) -> void:
	party.erase(unit)
	_sync_formation_line()

	if _is_open:
		_rebuild_tabs()
		_rebuild_formation_row()

	party_changed.emit()
	print("[PartyManager] Removed from party (died): %s" % unit.unit_name)

## =========================
## MENU OPEN / CLOSE
## =========================

func open_menu() -> void:
	if not GameManager.can_open_party_menu():
		push_warning("PartyManager: Cannot open menu during battle or while another menu is open.")
		return

	_is_open = true
	GameManager.current_state = GameManager.game_state.menu
	GameManager.party_menu_opened.emit()
	visible=true
	
	_rebuild_tabs()
	_rebuild_formation_row()

	if tab_container:
		tab_container.current_tab = get_initial_tab()

	menu_opened.emit()


func close_menu() -> void:
	if not _is_open:
		return

	_is_open = false
	GameManager.current_state = GameManager.game_state.not_battle
	GameManager.party_menu_closed.emit()
	menu_closed.emit()
	visible=false

	if not persist_selected_tab:
		_last_selected_tab = 0


func is_menu_open() -> bool:
	return _is_open

## =========================
## TAB REBUILDING
## =========================

func _rebuild_tabs() -> void:
	if tab_container == null or unit_panel_scene == null:
		push_warning("PartyManager: tab_container or unit_panel_scene not assigned.")
		return

	# free() is immediate — no await needed, no risk of concurrent rebuilds.
	for child in tab_container.get_children():
		child.free()

	for unit in party:
		if not is_instance_valid(unit):
			continue
		var panel = unit_panel_scene.instantiate()
		tab_container.add_child(panel)
		panel.name = unit.unit_name
		panel.setup(unit, self)


func _on_tab_changed(tab_index: int) -> void:
	set_last_selected_tab(tab_index)

## =========================
## FORMATION ROW REBUILDING
## =========================

func _rebuild_formation_row() -> void:
	if formation_row == null or formation_card_scene == null:
		push_warning("PartyManager: formation_row or formation_card_scene not assigned.")
		return

	for child in formation_row.get_children():
		child.free()

	for i in party.size():
		var unit := party[i]
		if not is_instance_valid(unit):
			continue
		var card = formation_card_scene.instantiate()
		formation_row.add_child(card)
		card.setup(unit, i, self)

## =========================
## FORMATION REORDERING
## =========================

func reorder_unit(from_index: int, to_index: int) -> void:
	if from_index == to_index:
		return
	if from_index < 0 or from_index >= party.size():
		push_error("PartyManager: reorder_unit() from_index out of range.")
		return
	if to_index < 0 or to_index >= party.size():
		push_error("PartyManager: reorder_unit() to_index out of range.")
		return

	var unit := party[from_index]
	party.remove_at(from_index)
	party.insert(to_index, unit)

	_sync_formation_line()

	if _is_open:
		_rebuild_formation_row()
		_rebuild_tabs()
		tab_container.current_tab = to_index

	party_changed.emit()


func _sync_formation_line() -> void:
	if formation_line == null:
		return
	formation_line.units.clear()
	for unit in party:
		if is_instance_valid(unit):
			formation_line.add_unit(unit)
	

## =========================
## TAB PERSISTENCE
## =========================

func set_last_selected_tab(index: int) -> void:
	_last_selected_tab = index


func get_initial_tab() -> int:
	if persist_selected_tab:
		return clamp(_last_selected_tab, 0, max(0, party.size() - 1))
	return 0

## =========================
## STAT GROWTH PATTERN EDITING
## =========================

func add_stat_gain(unit: Unit) -> void:
	if unit == null:
		return
	if unit.stat_growth_pattern.size() >= MAX_STAT_GAINS:
		push_warning("PartyManager: Stat growth pattern is full for '%s'." % unit.unit_name)
		return

	var gain := StatGain.new()
	gain.stat = StatGain.Stat.strength
	gain.amount = 1
	unit.stat_growth_pattern.append(gain)
	stat_growth_changed.emit(unit)


func remove_stat_gain(unit: Unit, index: int) -> void:
	if unit == null:
		return
	if index < 0 or index >= unit.stat_growth_pattern.size():
		push_error("PartyManager: remove_stat_gain() index out of range.")
		return

	unit.stat_growth_pattern.remove_at(index)

	if unit.stat_growth_pattern.size() > 0:
		unit._stat_growth_index = clamp(
			unit._stat_growth_index,
			0,
			unit.stat_growth_pattern.size() - 1
		)
	else:
		unit._stat_growth_index = 0

	stat_growth_changed.emit(unit)


func reorder_stat_gain(unit: Unit, from_index: int, to_index: int) -> void:
	if unit == null or from_index == to_index:
		return
	var pattern := unit.stat_growth_pattern
	if from_index < 0 or from_index >= pattern.size():
		return
	if to_index < 0 or to_index >= pattern.size():
		return

	var entry: StatGain = pattern[from_index]
	pattern.remove_at(from_index)
	pattern.insert(to_index, entry)
	stat_growth_changed.emit(unit)


func set_stat_gain_stat(unit: Unit, index: int, new_stat: StatGain.Stat) -> void:
	if unit == null:
		return
	if index < 0 or index >= unit.stat_growth_pattern.size():
		push_error("PartyManager: set_stat_gain_stat() index out of range.")
		return

	unit.stat_growth_pattern[index].stat = new_stat
	stat_growth_changed.emit(unit)


func get_stat_growth_summary(unit: Unit) -> String:
	if unit == null or unit.stat_growth_pattern.is_empty():
		return "(no pattern)"
	var parts: Array[String] = []
	for i in unit.stat_growth_pattern.size():
		var g: StatGain = unit.stat_growth_pattern[i]
		var marker := " <" if i == (unit._stat_growth_index % unit.stat_growth_pattern.size()) else ""
		parts.append("%d: %s+1%s" % [i, StatGain.Stat.keys()[g.stat], marker])
	return ", ".join(parts)
