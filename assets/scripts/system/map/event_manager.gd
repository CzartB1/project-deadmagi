class_name EventManager
extends Node2D

## =========================
## EXPORTS
## =========================

@export var battle_manager: BattleManager
@export var encounter_manager: RandomEncounterManager
@export var diff_manager: DifficultyManager
@export var victory_screen: Control
@export var zone_end_screen: Control
#@export var random_events: Array[DialogueResource]
@export var map_ui: MapUI
@export var unit_parent: Node
@export var party_manager: PartyManager

@export_group("Zone Event Quotas")
## How many shop slots appear across all EventNodes in a zone.
@export var shop_count_min: int = 1
@export var shop_count_max: int = 2
## How many random event slots appear.
@export var random_count_min: int = 1
@export var random_count_max: int = 3
## How many elite battle slots appear.
@export var elite_count_min: int = 0
@export var elite_count_max: int = 2

## =========================
## STATE
## =========================

var current_event: MapNode
var nodes: Array[MapNode]

## =========================
## LIFECYCLE
## =========================

func _ready():
	GameManager.recruit_requested.connect(_recruit_unit)
	GameManager.random_recruit_requested.connect(_recruit_random_unit)

func _process(_delta):
	if nodes.size() == 0:
		var t = get_tree().get_nodes_in_group("MapNode")
		for l in t:
			if l is MapNode and not nodes.has(l):
				nodes.append(l)
				l.manager = self
		# Once all nodes are collected, do the initial zone setup
		if nodes.size() > 0:
			setup_zone_events()

	if Input.is_action_just_pressed("cheat_god_mode"):
		for i in get_tree().get_nodes_in_group("Unit"):
			if i is Unit and i.is_ally:
				i.god_mode = !i.god_mode
				print("[event manager] god mode enabled: ", str(i.god_mode))

## =========================
## ZONE EVENT SETUP
## =========================

## Collects all EventNode slots across the zone, builds a shuffled type pool,
## and distributes it. Called on zone start and every loop reset.
func setup_zone_events() -> void:
	var event_nodes := _get_event_nodes()
	if event_nodes.is_empty():
		return

	# Count total slots
	var total_slots := 0
	for node in event_nodes:
		total_slots += node.length

	# Roll quotas, clamped so they never exceed total slots combined
	var shop_count  := randi_range(shop_count_min,   shop_count_max)
	var random_count := randi_range(random_count_min, random_count_max)
	var elite_count  := randi_range(elite_count_min,  elite_count_max)

	# Clamp total specials to available slots, preserving relative ratios
	var total_specials := shop_count + random_count + elite_count
	if total_specials > total_slots:
		var scale := float(total_slots) / float(total_specials)
		shop_count   = int(shop_count   * scale)
		random_count = int(random_count * scale)
		elite_count  = int(elite_count  * scale)
		total_specials = shop_count + random_count + elite_count

	var battle_count := total_slots - total_specials

	# Build flat type pool
	var pool: Array[Event.eventType] = []
	for i in shop_count:   pool.append(Event.eventType.shop)
	for i in random_count: pool.append(Event.eventType.random)
	for i in elite_count:  pool.append(Event.eventType.elite)
	for i in battle_count: pool.append(Event.eventType.battle)

	# Shuffle
	pool.shuffle()

	# Distribute across event node slots in order
	var pool_index := 0
	for node in event_nodes:
		for i in node.length:
			if pool_index >= pool.size():
				break
			node.events[i].type = pool[pool_index]
			pool_index += 1
		# Update the node's label to reflect its new composition
		_update_node_label(node)

	print("[event manager] zone setup: %d battles, %d elites, %d randoms, %d shops across %d slots"
		% [battle_count, elite_count, random_count, shop_count, total_slots])


func _get_event_nodes() -> Array:
	var result := []
	for node in nodes:
		if node is EventNode:
			result.append(node)
	return result


func _update_node_label(node: EventNode) -> void:
	var label := ""
	for e in node.events:
		match e.type:
			Event.eventType.battle:  label += "[B]"
			Event.eventType.elite:   label += "[E]"
			Event.eventType.random:  label += "[R]"
			Event.eventType.shop:    label += "[S]"
	node.text = label

## =========================
## BATTLE
## =========================

## encounter_type added as optional parameter for elite support
func start_battle(
	specific: bool = false,
	index: int = 0,
	unlisted: bool = false,
	encounter_type: DifficultyManager.EncounterType = DifficultyManager.EncounterType.NORMAL
):
	randomize()
	if not specific:
		encounter_manager.start_random_encounter(encounter_type)
	else:
		if unlisted:
			encounter_manager.start_unlisted_encounter(index)
		else:
			encounter_manager.start_encounter(index)

## =========================
## MAP FLOW
## =========================

func next_event():
	victory_screen.visible = false
	zone_end_screen.visible = false
	if current_event is EventNode:
		current_event.next_event()
	elif current_event is BossNode:
		map_ui.loop()
		current_event.complete()

func next_zone():
	zone_end_screen.visible = false
	if current_event is BossNode:
		map_ui.loop()
		diff_manager.advance_zone()
		current_event.complete()

## =========================
## RECRUIT
## =========================

func _recruit_unit(recruited_unit: PackedScene):
	if recruited_unit == null:
		return
	print("[event manager] recruit requested")

	var unit := recruited_unit.instantiate()
	if not unit is Unit:
		unit.queue_free()
		return

	unit.is_ally = true
	unit_parent.add_child(unit)
	unit.add_to_group("Unit")

	if unit.is_ally:
		battle_manager.ally_line.add_unit(unit)
		party_manager.register_unit(unit)
	else:
		battle_manager.enemy_line.add_unit(unit)

func _recruit_random_unit():
	_recruit_unit(diff_manager._get_unit_random())
