class_name ItemEquipMenu
extends Control

@export var unit_row_scene: PackedScene
@export var unit_list_container: VBoxContainer
@export var title_label: RichTextLabel
@export var desc_label: RichTextLabel
#@export var cancel_button: Button
@export var skip_button: Button
#@export var skip_label: RichTextLabel  # shows how much gold you'd get

@export var economy_manager: EconomyManager

var pending_item_scene: PackedScene
var _current_encounter_type: DifficultyManager.EncounterType = DifficultyManager.EncounterType.NORMAL

func _ready():
	visible = false
	#cancel_button.pressed.connect(close)
	skip_button.pressed.connect(_on_skip_pressed)
	GameManager.item_requested.connect(open)

## Opens the menu. encounter_type is used to calculate the skip gold reward.
func open(item_scene: PackedScene, encounter_type: DifficultyManager.EncounterType = DifficultyManager.EncounterType.NORMAL):
	pending_item_scene = item_scene
	_current_encounter_type = encounter_type
	visible = true

	var temp_item = item_scene.instantiate()
	await get_tree().process_frame
	title_label.text = "Equip Item:\n[b]%s[/b]" % temp_item.item_name
	desc_label.text = str(temp_item.description)
	temp_item.queue_free()

	_update_skip_label()
	_rebuild_unit_list()

func close():
	visible = false
	pending_item_scene = null

func _update_skip_label():
	if not economy_manager or not skip_button:
		return
	var reward := economy_manager.get_skip_reward(_current_encounter_type)
	skip_button.text = "Skip (+%d gold)" % reward

func _on_skip_pressed():
	if not economy_manager:
		push_warning("ItemEquipMenu: no EconomyManager assigned.")
		close()
		return
	var reward := economy_manager.award_skip(_current_encounter_type)
	print("[item menu] player skipped item, received %d gold" % reward)
	close()

func _rebuild_unit_list():
	for c in unit_list_container.get_children():
		c.queue_free()

	var units := get_tree().get_nodes_in_group("Unit")
	units = units.filter(func(u: Unit): return u.is_ally and u.alive)

	for u in units:
		var row: UnitEquipRow = unit_row_scene.instantiate()
		row.setup(u)
		row.slot_pressed.connect(_on_slot_pressed)
		unit_list_container.add_child(row)

func _on_slot_pressed(unit: Unit, slot_index: int):
	if not pending_item_scene:
		return
	var item := pending_item_scene.instantiate()
	unit.equip_item(slot_index, item)
	print("[item menu] ", unit.unit_name, " receives a ", item.item_name, " at slot ", str(slot_index))
	close()
