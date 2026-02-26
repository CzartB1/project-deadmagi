extends Control
class_name TurnOrderUI

@export var battle_manager: BattleManager
@export var scroll: ScrollContainer
@export var hbox: HBoxContainer
@export var item_scene: PackedScene

@export var build_delay := 0.25
@export var slide_time := 0.5
@export var hidden_offset := -120.0

var items: Dictionary = {}
var tween: Tween

func _ready():
	if battle_manager:
		battle_manager.battle_started.connect(on_battle_started)
		battle_manager.battle_ended.connect(on_battle_ended)

	# start hidden
	position.y += hidden_offset
	visible = false
	set_process(true)

func on_battle_started():
	visible = true
	await get_tree().create_timer(build_delay).timeout
	rebuild()
	slide_in()

func on_battle_ended(_victory := false):
	slide_out()
	clear()

func rebuild():
	clear()
	if not battle_manager:
		return

	for unit in battle_manager.turn_queue:
		if not is_instance_valid(unit):
			continue
		var item := item_scene.instantiate() as TurnOrderItem
		hbox.add_child(item)
		item.setup(unit)
		items[unit] = item

	scroll.scroll_horizontal = 0

func clear():
	for c in hbox.get_children():
		c.queue_free()
	items.clear()

func _process(_delta):
	if not battle_manager:
		return

	var current := battle_manager.current_unit
	var to_remove: Array[Unit] = []

	for unit in items.keys():
		if not is_instance_valid(unit):
			to_remove.append(unit)
			continue
		items[unit].set_active(unit == current)

	for u in to_remove:
		items.erase(u)

# --------------------
# Animation helpers
# --------------------

func slide_in():
	position.y+hidden_offset
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(
		self,
		"position:y",
		position.y - hidden_offset,
		slide_time
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func slide_out():
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(
		self,
		"position:y",
		position.y + hidden_offset,
		slide_time
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
