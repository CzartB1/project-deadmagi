extends Node
class_name DifficultyManager

## =========================
## ENUMS / CONSTANTS
## =========================

enum EncounterType {
	NORMAL,
	ELITE,
	BOSS,
	EVENT,
	ITEM
}

const ELITE_OFFSET := 1
const BOSS_OFFSET  := 2

## =========================
## EXPORTED DATA
## =========================

@export var zone_tiers: Array[ZoneTier] = [] 
#@export var starting_zone: Zone
var _current_zone: Zone
var _current_tier: int = 0

@export var secret_enemy_pools: Array[EncounterPool] = []   # optional overlay pools
@export var secret_elite_pools: Array[EncounterPool] = []
@export var secret_boss_pools: Array[EncounterPool] = []

@export var secret_threshold := 6   # difficulty index where secrets unlock

@export var difficulty_label: RichTextLabel
@export var item_screen: ItemEquipMenu
@export var economy_manager: EconomyManager

## =========================
## RUNTIME STATE
## =========================

var _current_difficulty: int = 0
var _loop_count: int = 0

## =========================
## LIFECYCLE
## =========================

func _ready():
	assert(zone_tiers.size() > 0, "No zone tiers defined.")
	assert(zone_tiers[0].zones.size() > 0, "Tier 0 has no zones.")

	_current_tier = 0
	_current_zone = zone_tiers[0].zones.pick_random()
	_current_zone.setup()

	_current_difficulty = 0
	difficulty_label.text = get_current_stage_string()

	GameManager.random_item_requested.connect(give_party_random_item)


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("cheat_add_difficulty"):
		_increase_difficulty(1)

## =========================
## PUBLIC API
## =========================

func get_current_difficulty_index() -> int:
	return _current_difficulty


func get_current_stage() -> DifficultyStage:
	var stages := _current_zone.get_stages()
	return stages[_current_difficulty]


func advance_zone():
	var stages := _current_zone.get_stages()

	# Still escalating inside zone
	#if _current_difficulty < stages.size() - 1:
		#_increase_difficulty(1)
		##return

	# Move to next tier
	if _current_tier < zone_tiers.size() - 1:
		_current_tier += 1
		var next_tier_zones: Array = zone_tiers[_current_tier].zones
		_current_zone = next_tier_zones.pick_random()
		_current_zone.setup()

		# IMPORTANT: difficulty does NOT reset
		difficulty_label.text = get_current_stage_string()
		return

	# End of final tier → loop
	loop_run()

func loop_stage(): #TODO remove
	_loop_count += 1
	_increase_difficulty(1)

func loop_run():
	_loop_count += 1
	_current_tier = 0
	_current_zone = zone_tiers[0].zones.pick_random()
	_current_zone.setup()

	# DO NOT reset difficulty
	difficulty_label.text = get_current_stage_string()

func set_difficulty(index: int):
	_current_difficulty = clamp(index, 0, _current_zone.get_stages().size() - 1)
	difficulty_label.text=get_current_stage_string()

func change_zone(new_zone: Zone):
	assert(new_zone != null)

	_current_zone = new_zone
	_current_zone.setup()
	difficulty_label.text = get_current_stage_string()


func get_available_next_zones() -> Array[Zone]:
	return _current_zone.next_zones

func get_context() -> Dictionary:
	var stage := get_current_stage()

	var loop_multiplier := 1.0 + (_loop_count * 0.25)

	return {
		"zone_name": _current_zone.zone_name,
		"tier": _current_tier,
		"difficulty_index": _current_difficulty,
		"difficulty_name": stage.display_name,
		"loop_count": _loop_count,
		"loop_multiplier": loop_multiplier,
		"is_terminal": stage.is_terminal,
		"modifiers": stage.modifiers.duplicate()
	}


func get_current_stage_string() -> String:
	var stage := get_current_stage()
	return "Current stage: "+str(_current_zone.zone_name)+"\nCurrent Difficulty: "+str(stage.display_name)

## =========================
## ENCOUNTER QUERIES
## =========================

func get_encounter(type: EncounterType, context := {}) -> Variant:
	match type:
		EncounterType.NORMAL:
			return _get_enemy_from_offset(0, context)

		EncounterType.ELITE:
			return _get_enemy_from_offset(ELITE_OFFSET, context)

		EncounterType.BOSS:
			return _get_enemy_from_offset(BOSS_OFFSET, context)

		EncounterType.EVENT:
			return _get_event(context)

		EncounterType.ITEM:
			return _get_item_random()

		_:
			push_error("DifficultyManager: Unknown EncounterType.")
			return null

## =========================
## SHOP QUERIES
## =========================

## Returns a randomized stock of items for the shop.
## Uses a weighted random difficulty offset (0–5, biased toward 0).
## stock_size: how many items to generate.
func get_shop_stock(stock_size: int = 4) -> Array:
	var stock := []
	var offset = economy_manager.roll_shop_offset() if economy_manager else 0
	var stages := _current_zone.get_stages()

	for i in stock_size:
		var target_index = clamp(_current_difficulty + offset, 0, stages.size() - 1)
		var stage := stages[target_index]

		if stage == null or stage.item_pools.is_empty():
			continue

		var item_scene: PackedScene = stage.item_pools.pick_random()
		if item_scene:
			stock.append({
				"scene": item_scene,
				"offset": offset,
				"price": _calculate_shop_price(item_scene, offset)
			})

	print("[difficulty] shop stock generated with offset +%d (%d items)" % [offset, stock.size()])
	return stock


func _calculate_shop_price(item_scene: PackedScene, offset: int) -> int:
	if not economy_manager:
		return 50
	var temp := item_scene.instantiate()
	var price := economy_manager.calculate_price(temp, _current_difficulty, offset)
	temp.free()
	return price

## =========================
## INTERNAL LOGIC
## =========================

func _increase_difficulty(amount: int):
	var stages := _current_zone.get_stages()

	_current_difficulty = clamp(
		_current_difficulty + amount,
		0,
		stages.size() - 1
	)

	difficulty_label.text = get_current_stage_string()


func _get_enemy_from_offset(offset: int, context := {}) -> EncounterPool:
	if _current_zone == null:
		push_error("DifficultyManager: No current zone set.")
		return null

	var stages := _current_zone.get_stages()

	if stages.is_empty():
		push_error("DifficultyManager: Zone has no stages.")
		return null

	var target_index = clamp(_current_difficulty, 0, stages.size() - 1)
	var stage := stages[target_index]

	if stage == null:
		push_error("DifficultyManager: Stage is null at index %d." % target_index)
		return null

	var pools: Array[EncounterPool] = []

	match offset:
		0:
			pools = stage.enemy_pools.duplicate()
		ELITE_OFFSET:
			pools = stage.elite_pools.duplicate()
		BOSS_OFFSET:
			pools = stage.boss_pools.duplicate()
		_:
			push_error("DifficultyManager: Invalid offset.")
			return null

	_overlay_secret_pools(pools, offset)

	pools = pools.filter(func(p): return p != null)

	if pools.is_empty():
		push_error(
			"DifficultyManager: No valid enemy pools in zone '%s' at difficulty %d (offset %d)"
			% [_current_zone.zone_name, target_index, offset]
		)
		return null

	return pools.pick_random()



func _get_event(context := {}) -> DialogueResource:
	var stage := get_current_stage()
	if stage.event_pools.is_empty():
		return null

	var pool = stage.event_pools.pick_random()
	return pool


func _get_item_random(item_pool := []) -> PackedScene:
	var stage := get_current_stage()
	if stage.item_pools.is_empty():
		return null
	
	if item_pool.is_empty():
		var pool = stage.item_pools.pick_random()
		return pool
	else:
		var pool = item_pool.pick_random()
		return pool

func give_party_random_item(pool: Array = [], encounter_type: DifficultyManager.EncounterType = DifficultyManager.EncounterType.NORMAL):
	item_screen.open(_get_item_random(pool), encounter_type)

func _get_unit_random() -> PackedScene:
	return get_current_stage().recruit_pool.pick_random()

func _overlay_secret_pools(pools: Array, offset: int):
	if _current_difficulty < secret_threshold:
		return

	match offset:
		0:
			pools.append_array(secret_enemy_pools)
		ELITE_OFFSET:
			pools.append_array(secret_elite_pools)
		BOSS_OFFSET:
			pools.append_array(secret_boss_pools)
