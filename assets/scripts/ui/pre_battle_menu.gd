extends Control
class_name PreBattleMenu

@export var unit_types: Array[PackedScene]
@export var battle_manager: BattleManager
@export var party_manager:PartyManager
@export var unit_parent: Node  # where units are spawned

@export var party_limit:int=4

@export var type_dropdown: OptionButton 
@export var name_input: LineEdit 
@export var ally_toggle: CheckBox 
@export var add_button: Button 
@export var start_button: Button

@export var preview_entry_scene: PackedScene
@export var preview_list: HBoxContainer

@export var map: Control

var preview_entries: Array[UnitPreviewEntry] = []


func _ready():
	_build_unit_type_dropdown()
	add_button.pressed.connect(_on_add_unit)
	start_button.pressed.connect(_on_start_battle)
	map.visible=false

func _build_unit_type_dropdown():
	type_dropdown.clear()

	for i in unit_types.size():
		var scene := unit_types[i]
		type_dropdown.add_item(scene.resource_path.get_file(), i)

func _on_add_unit():
	if unit_types.is_empty():
		return

	var index := type_dropdown.get_selected_id()
	var scene := unit_types[index]

	var unit := scene.instantiate()
	if not unit is Unit:
		unit.queue_free()
		return

	var custom_name := name_input.text.strip_edges()
	if not custom_name.is_empty():
		unit.unit_name = custom_name

	#unit.is_ally = ally_toggle.button_pressed
	unit.is_ally = true
	party_manager.register_unit(unit)

	unit_parent.add_child(unit)
	unit.add_to_group("Unit")

	_add_preview_entry(unit)

	name_input.text = ""
	
	if unit.is_ally: battle_manager.ally_line.add_unit(unit)
	else:battle_manager.enemy_line.add_unit(unit)
	if preview_list.get_children().size()+1>party_limit: 
		add_button.disabled=true

func _add_preview_entry(unit: Unit):
	var entry: UnitPreviewEntry = preview_entry_scene.instantiate()
	entry.setup(unit, _remove_unit)
	preview_list.add_child(entry)
	preview_entries.append(entry)

func _remove_unit(entry: UnitPreviewEntry, unit: Unit):
	if is_instance_valid(unit):
		unit.queue_free()

	preview_entries.erase(entry)
	entry.queue_free()
	if preview_entries.size()<party_limit:
		add_button.disabled=false

func _on_start_battle():
	if _no_valid_teams():
		return

	visible = false
	battle_manager.start_battle()

func _no_valid_teams() -> bool:
	var has_ally := false
	var has_enemy := false

	for entry in preview_entries:
		if not is_instance_valid(entry.unit):
			continue
		if entry.unit.is_ally:
			has_ally = true
		else:
			has_enemy = true

	return not (has_ally and has_enemy)

func _on_battle_manager_battle_started():
	if visible: visible = false

func open_map():
	visible=false
	map.visible=true
