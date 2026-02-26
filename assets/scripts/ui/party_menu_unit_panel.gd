class_name UnitPanel
extends Control

## =========================
## EXPECTED NODE STRUCTURE
## =========================
##
## UnitPanel (Control)
## ├── Header
## │   ├── Portrait (TextureRect)
## │   └── NameLabel (Label)
## ├── SubTabs (TabContainer)
## │   ├── Stats (Control)
## │   │   ├── HPLabel (Label)
## │   │   ├── MoraleLabel (Label)
## │   │   ├── LevelLabel (Label)
## │   │   ├── XPLabel (Label)
## │   │   ├── StrengthLabel (Label)
## │   │   ├── AgilityLabel (Label)
## │   │   ├── BodyLabel (Label)
## │   │   ├── MindLabel (Label)
## │   │   └── WillLabel (Label)
## │   ├── Items (Control)
## │   │   └── ItemSlotContainer (HBoxContainer)  ← slots built at runtime
## │   ├── Lore (Control)
## │   │   └── BackstoryLabel (RichTextLabel)
## │   └── Growth (Control)
## │       ├── GrowthList (VBoxContainer)
## │       └── AddButton (Button)

## =========================
## EXPORTS — assign all in the inspector
## =========================

@export_group("Header")
@export var portrait_rect: TextureRect
@export var name_label: RichTextLabel

@export_group("Stats")
@export var hp_label: RichTextLabel
@export var morale_label: RichTextLabel
@export var level_label: RichTextLabel
@export var xp_label: RichTextLabel
@export var strength_label: RichTextLabel
@export var agility_label: RichTextLabel
@export var body_label: RichTextLabel
@export var mind_label: RichTextLabel
@export var will_label: RichTextLabel

@export_group("Items")
## HBoxContainer that item slot panels are built into at runtime.
@export var item_slot_container: HBoxContainer
## Scene for a single item slot. Must have a Label named "SlotName"
## and a Label named "SlotDesc" as children.
@export var item_slot_scene: PackedScene

@export_group("Lore")
@export var backstory_label: RichTextLabel

@export_group("Growth")
@export var growth_list: VBoxContainer
@export var add_button: Button

## =========================
## RUNTIME STATE
## =========================

var _unit: Unit = null
var _party_manager: PartyManager = null

const STAT_NAMES := ["Strength", "Agility", "Body", "Mind", "Will"]

## =========================
## SETUP
## =========================

func setup(unit: Unit, party_manager: PartyManager) -> void:
	_unit = unit
	_party_manager = party_manager

	_populate_header()
	_populate_stats()
	_populate_items()
	_populate_lore()
	_populate_growth()

	if not unit.damaged.is_connected(_on_unit_changed):
		unit.damaged.connect(_on_unit_changed)
	if not unit.morale_damaged.is_connected(_on_unit_changed):
		unit.morale_damaged.connect(_on_unit_changed)
	if not unit.levelled_up.is_connected(_on_unit_levelled_up):
		unit.levelled_up.connect(_on_unit_levelled_up)

	if not party_manager.stat_growth_changed.is_connected(_on_stat_growth_changed):
		party_manager.stat_growth_changed.connect(_on_stat_growth_changed)

	if add_button:
		add_button.pressed.connect(_on_add_stat_gain_pressed)

## =========================
## POPULATE SECTIONS
## =========================

func _populate_header() -> void:
	if name_label:
		name_label.text = _unit.unit_name
	if portrait_rect:
		portrait_rect.texture = _unit.portrait if _unit.portrait else null


func _populate_stats() -> void:
	if hp_label:     hp_label.text     = "HP: %d / %d" % [_unit.current_hp, _unit.max_hp]
	if morale_label: morale_label.text = "Morale: %d / %d" % [_unit.current_morale, _unit.max_morale]
	if level_label:  level_label.text  = "Level: %d" % _unit.current_level
	if xp_label:     xp_label.text     = "XP: %d / %d" % [_unit.current_xp, _unit.xp_to_next_level]

	if strength_label: strength_label.text = _stat_string("STR", _unit.base_strength, _unit.strength)
	if agility_label:  agility_label.text  = _stat_string("AGI", _unit.base_agility,  _unit.agility)
	if body_label:     body_label.text     = _stat_string("BOD", _unit.base_body,     _unit.body)
	if mind_label:     mind_label.text     = _stat_string("MND", _unit.base_mind,     _unit.mind)
	if will_label:     will_label.text     = _stat_string("WIL", _unit.base_will,     _unit.will)


func _stat_string(abbr: String, base: int, total: int) -> String:
	if total != base:
		return "%s: %d  (+%d from items = %d)" % [abbr, base, total - base, total]
	return "%s: %d" % [abbr, base]


func _populate_items() -> void:
	if item_slot_container == null or item_slot_scene == null:
		push_warning("UnitPanel: item_slot_container or item_slot_scene not assigned.")
		return

	for child in item_slot_container.get_children():
		child.queue_free()

	await get_tree().process_frame

	for i in _unit.max_item_slots:
		var slot = item_slot_scene.instantiate()
		item_slot_container.add_child(slot)

		var item: Item = _unit.equipped_items[i] if i < _unit.equipped_items.size() else null
		var slot_name: RichTextLabel = slot.get_child(0).get_node_or_null("SlotName")
		var slot_desc: RichTextLabel = slot.get_child(0).get_node_or_null("SlotDesc")

		if slot_name:
			slot_name.text = item.item_name if item else "Empty"
		if slot_desc:
			slot_desc.text = item.description if item else ""


func _populate_lore() -> void:
	if backstory_label:
		backstory_label.text = _unit.backstory if not _unit.backstory.is_empty() \
			else "(No backstory yet.)"


func _populate_growth() -> void:
	if growth_list == null:
		return

	for child in growth_list.get_children():
		child.queue_free()

	await get_tree().process_frame

	for i in _unit.stat_growth_pattern.size():
		_add_growth_row(i)

	if add_button:
		add_button.disabled = _unit.stat_growth_pattern.size() >= PartyManager.MAX_STAT_GAINS

	_update_growth_cursor_labels()

## =========================
## STAT GROWTH ROW BUILDING
## =========================

func _add_growth_row(index: int) -> void:
	var gain: StatGain = _unit.stat_growth_pattern[index]

	var row := HBoxContainer.new()
	row.name = "GrowthRow_%d" % index

	var up_btn := Button.new()
	up_btn.text = "↑"
	up_btn.disabled = (index == 0)
	up_btn.pressed.connect(_on_move_up_pressed.bind(index))
	row.add_child(up_btn)

	var dn_btn := Button.new()
	dn_btn.text = "↓"
	dn_btn.disabled = (index == _unit.stat_growth_pattern.size() - 1)
	dn_btn.pressed.connect(_on_move_down_pressed.bind(index))
	row.add_child(dn_btn)

	var opt := OptionButton.new()
	for stat_name in STAT_NAMES:
		opt.add_item(stat_name)
	opt.selected = gain.stat as int
	opt.item_selected.connect(_on_stat_selected.bind(index))
	row.add_child(opt)

	var rm_btn := Button.new()
	rm_btn.text = "✕"
	rm_btn.pressed.connect(_on_remove_stat_gain_pressed.bind(index))
	row.add_child(rm_btn)

	var next_label := Label.new()
	next_label.name = "NextMarker"
	var cursor = _unit._stat_growth_index % max(_unit.stat_growth_pattern.size(), 1)
	next_label.text = "← next" if index == cursor else ""
	row.add_child(next_label)

	growth_list.add_child(row)


func _update_growth_cursor_labels() -> void:
	if _unit == null or _unit.stat_growth_pattern.is_empty():
		return
	var cursor := _unit._stat_growth_index % _unit.stat_growth_pattern.size()
	for i in growth_list.get_child_count():
		var row := growth_list.get_child(i)
		var marker := row.get_node_or_null("NextMarker")
		if marker:
			marker.text = "← next" if i == cursor else ""

## =========================
## SIGNAL HANDLERS
## =========================

func _on_unit_changed(_context := {}) -> void:
	if _unit:
		_populate_stats()


func _on_unit_levelled_up(_new_level: int) -> void:
	if _unit:
		_populate_stats()
		_update_growth_cursor_labels()


func _on_stat_growth_changed(changed_unit: Unit) -> void:
	if changed_unit == _unit:
		_populate_growth()


func _on_add_stat_gain_pressed() -> void:
	_party_manager.add_stat_gain(_unit)


func _on_remove_stat_gain_pressed(index: int) -> void:
	_party_manager.remove_stat_gain(_unit, index)


func _on_move_up_pressed(index: int) -> void:
	if index > 0:
		_party_manager.reorder_stat_gain(_unit, index, index - 1)


func _on_move_down_pressed(index: int) -> void:
	if index < _unit.stat_growth_pattern.size() - 1:
		_party_manager.reorder_stat_gain(_unit, index, index + 1)


func _on_stat_selected(stat_index: int, row_index: int) -> void:
	_party_manager.set_stat_gain_stat(_unit, row_index, stat_index as StatGain.Stat)
