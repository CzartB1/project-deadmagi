class_name EconomyManager
extends Node

## =========================
## CONSTANTS
## =========================

const BASE_SKIP_REWARD := 15
const BASE_REROLL_COST := 10

## Encounter type multipliers (mirrors BattleManager XP multipliers)
const NORMAL_MULT  := 1.0
const ELITE_MULT   := 1.5
const BOSS_MULT    := 2.5

## Shop difficulty offset weights [offset: weight]
## Weights don't need to sum to 100 — they're relative
const OFFSET_WEIGHTS := {
	0: 55,
	1: 25,
	2: 12,
	3: 5,
	4: 2,
	5: 1
}

## =========================
## SIGNALS
## =========================

signal gold_changed(new_amount: int)

## =========================
## STATE
## =========================

var gold: int = 0
var _reroll_cost: int = BASE_REROLL_COST
var _reroll_count: int = 0

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("cheat_gold"): debug_add_gold()

## =========================
## GOLD API
## =========================

func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)
	print("[economy] added %d gold (total: %d)" % [amount, gold])

func spend_gold(amount: int) -> bool:
	if not can_afford(amount):
		print("[economy] not enough gold (have %d, need %d)" % [gold, amount])
		return false
	gold -= amount
	gold_changed.emit(gold)
	print("[economy] spent %d gold (total: %d)" % [amount, gold])
	return true

func can_afford(amount: int) -> bool:
	return gold >= amount

func debug_add_gold(): 
	print("[economy] cheater fuck ass.")
	add_gold(99999)

## =========================
## SKIP REWARD
## =========================

func get_skip_reward(encounter_type: DifficultyManager.EncounterType) -> int:
	var mult := NORMAL_MULT
	match encounter_type:
		DifficultyManager.EncounterType.ELITE:
			mult = ELITE_MULT
		DifficultyManager.EncounterType.BOSS:
			mult = BOSS_MULT
	return int(BASE_SKIP_REWARD * mult)

func award_skip(encounter_type: DifficultyManager.EncounterType) -> int:
	var amount := get_skip_reward(encounter_type)
	add_gold(amount)
	return amount

## =========================
## REROLL
## =========================

func get_reroll_cost() -> int:
	return _reroll_cost

func reroll(spend: bool = true) -> bool:
	if spend and not spend_gold(_reroll_cost):
		return false
	_reroll_count += 1
	_reroll_cost = BASE_REROLL_COST * (1 << _reroll_count) # doubles each time: 10, 20, 40, 80...
	print("[economy] reroll #%d, next reroll costs %d" % [_reroll_count, _reroll_cost])
	return true

func reset_reroll() -> void:
	_reroll_cost = BASE_REROLL_COST
	_reroll_count = 0

## =========================
## SHOP OFFSET
## =========================

## Returns a weighted-random difficulty offset for shop stock generation.
func roll_shop_offset() -> int:
	var total_weight := 0
	for w in OFFSET_WEIGHTS.values():
		total_weight += w

	var roll := randi_range(0, total_weight - 1)
	var cumulative := 0

	for offset in OFFSET_WEIGHTS.keys():
		cumulative += OFFSET_WEIGHTS[offset]
		if roll < cumulative:
			print("[economy] shop offset rolled: +%d" % offset)
			return offset

	return 0 # fallback

## =========================
## ITEM PRICE
## =========================

func calculate_price(item: Item, difficulty_index: int, offset: int) -> int:
	var effective_difficulty := difficulty_index + offset
	var scalar := 1.0 + (effective_difficulty * 0.1)
	return int(item.base_price * scalar)
