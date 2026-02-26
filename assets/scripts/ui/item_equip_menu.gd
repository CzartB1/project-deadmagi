class_name ItemEquipMenu
extends Control

@export var unit_row_scene: PackedScene
@export var unit_list_container: VBoxContainer
@export var title_label: RichTextLabel
@export var desc_label: RichTextLabel
@export var cancel_button: Button

var pending_item_scene: PackedScene

func _ready():
	visible = false
	#title_label.mouse_filter = Control.MOUSE_FILTER_STOP
	cancel_button.pressed.connect(close)
	GameManager.item_requested.connect(open)

func open(item_scene: PackedScene):
	pending_item_scene = item_scene
	visible = true
	var temp_item = item_scene.instantiate()
	await get_tree().process_frame  # let the node fully initialize
	print(temp_item.item_name)
	print(temp_item.description)
	title_label.text = "Equip Item:\n[b]%s[/b]" % temp_item.item_name
	desc_label.text = str(temp_item.description) #FIXME wont show
	temp_item.queue_free()
	_rebuild_unit_list()

func close():
	visible = false
	pending_item_scene = null

func _rebuild_unit_list():
	for c in unit_list_container.get_children():
		c.queue_free()

	var units := get_tree().get_nodes_in_group("Unit")
	units = units.filter(func(u: Unit):
		return u.is_ally and u.alive
	)

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
	print("[Item Menu] ", unit.unit_name, " receives a ", item.item_name, " at slot ", str(slot_index))
	close()
