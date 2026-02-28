class_name ShopUI
extends Control

## =========================
## EXPORTS
## =========================

@export var item_list_container: VBoxContainer
@export var reroll_button: Button
#@export var reroll_cost_label: RichTextLabel
@export var gold_label: RichTextLabel
@export var close_button: Button
@export var item_slot_scene: PackedScene  # reuse the same slot scene from ItemEquipMenu

@export var economy_manager: EconomyManager
@export var diff_manager: DifficultyManager

@export var stock_size: int = 4

## =========================
## STATE
## =========================

var _current_stock: Array = []  # Array of {scene, offset, price}

## =========================
## SIGNALS
## =========================

signal shop_closed

## =========================
## LIFECYCLE
## =========================

func _ready():
	visible = false
	close_button.pressed.connect(_on_close_pressed)
	reroll_button.pressed.connect(_on_reroll_pressed)
	if economy_manager:
		economy_manager.gold_changed.connect(_on_gold_changed)
	reroll_button.text = "Reroll: %d gold" % economy_manager.get_reroll_cost()

## =========================
## PUBLIC API
## =========================

func open() -> void:
	economy_manager.reset_reroll()
	visible = true
	_generate_stock()
	_refresh_gold_label()
	_refresh_reroll_button()

func close() -> void:
	visible = false
	shop_closed.emit()

## =========================
## STOCK
## =========================

func _generate_stock() -> void:
	_current_stock = diff_manager.get_shop_stock(stock_size)
	_rebuild_item_list()

func _rebuild_item_list() -> void:
	for child in item_list_container.get_children():
		child.queue_free()

	await get_tree().process_frame

	if _current_stock.is_empty():
		var empty_label := RichTextLabel.new()
		empty_label.bbcode_enabled = true
		empty_label.fit_content = true
		empty_label.text = "[i]No items available.[/i]"
		item_list_container.add_child(empty_label)
		return

	for i in _current_stock.size():
		var entry: Dictionary = _current_stock[i]
		_add_shop_entry(entry, i)

func _add_shop_entry(entry: Dictionary, index: int) -> void:
	var temp_item: Item = entry.scene.instantiate()
	var price: int = entry.price
	var can_buy := economy_manager.can_afford(price)

	var row := HBoxContainer.new()
	row.name = "ShopEntry_%d" % index

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var name_label := RichTextLabel.new()
	name_label.bbcode_enabled = true
	name_label.fit_content = true
	name_label.scroll_active = false
	name_label.text = "[b]%s[/b]  —  %d gold" % [temp_item.item_name, price]
	info.add_child(name_label)

	var desc_label := RichTextLabel.new()
	desc_label.bbcode_enabled = true
	desc_label.fit_content = true
	desc_label.scroll_active = false
	desc_label.text = "[i]%s[/i]" % temp_item.description
	info.add_child(desc_label)

	row.add_child(info)

	var buy_btn := Button.new()
	buy_btn.text = "Buy"
	buy_btn.disabled = not can_buy
	buy_btn.pressed.connect(_on_buy_pressed.bind(index, buy_btn))
	row.add_child(buy_btn)

	item_list_container.add_child(row)

	temp_item.queue_free()

## =========================
## BUYING
## =========================

func _on_buy_pressed(index: int, buy_btn: Button) -> void:
	if index >= _current_stock.size():
		return

	var entry: Dictionary = _current_stock[index]
	var price: int = entry.price

	if not economy_manager.spend_gold(price):
		return

	# Open the unit selection via ItemEquipMenu
	# We pass the scene to GameManager which routes it to ItemEquipMenu
	GameManager.item_requested.emit(entry.scene)

	# Remove from stock so it can't be bought twice
	_current_stock.remove_at(index)
	_rebuild_item_list()
	_refresh_gold_label()
	_refresh_reroll_button()

## =========================
## REROLL
## =========================

func _on_reroll_pressed() -> void:
	if not economy_manager.reroll():
		return
	_generate_stock()
	_refresh_reroll_button()
	_refresh_gold_label()

func _refresh_reroll_button() -> void:
	if not economy_manager or not reroll_button:
		return
	var cost := economy_manager.get_reroll_cost()
	var affordable := economy_manager.can_afford(cost)
	reroll_button.disabled = not affordable
	reroll_button.text = "Reroll: %d gold" % cost
	#if reroll_cost_label:
		#reroll_cost_label.text = "Reroll: %d gold" % cost

## =========================
## GOLD DISPLAY
## =========================

func _on_gold_changed(new_amount: int) -> void:
	_refresh_gold_label()
	_refresh_reroll_button()
	# Refresh buy buttons in case affordability changed
	_rebuild_item_list()

func _refresh_gold_label() -> void:
	if not economy_manager or not gold_label:
		return
	gold_label.text = "Gold: %d" % economy_manager.gold

## =========================
## CLOSE
## =========================

func _on_close_pressed() -> void:
	close()
