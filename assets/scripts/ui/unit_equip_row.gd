class_name UnitEquipRow
extends Control

signal slot_pressed(unit: Unit, slot_index: int)

var unit: Unit

@export var portrait_rect: TextureRect
@export var name_label: RichTextLabel
@export var slots_container: VBoxContainer
@export var slot_button_scene: PackedScene

func setup(u: Unit):
	unit = u
	name_label.text = "[b]"+u.unit_name

	#if portrait_rect and u.model and u.model.portrait:
		#portrait_rect.texture = u.model.portrait

	_rebuild_slots()

func _rebuild_slots():
	for c in slots_container.get_children():
		c.queue_free()

	for i in range(unit.max_item_slots):
		var btn: Button = slot_button_scene.instantiate()
		btn.toggle_mode = false
		btn.custom_minimum_size = Vector2(48, 48)

		if i < unit.equipped_items.size() and unit.equipped_items[i] is Item:
			var item := unit.equipped_items[i]
			btn.text = item.item_name
			btn.tooltip_text = item.item_name
		else:
			btn.size_flags_horizontal=Control.SIZE_EXPAND_FILL
			btn.text = "+"
			btn.autowrap_mode = TextServer.AUTOWRAP_OFF
			btn.tooltip_text = "Empty slot"

		btn.pressed.connect(_on_slot_pressed.bind(i))
		slots_container.add_child(btn)

func _on_slot_pressed(slot_index: int):
	emit_signal("slot_pressed", unit, slot_index)
