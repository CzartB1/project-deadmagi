extends Node
class_name RandomEncounterManager

@export var difficulty_manager: DifficultyManager
@export var encounter_pools: Array[EncounterPool] = []
@export var unlisted_encounter_pools: Array[EncounterPool] = []
@export var enemy_parent: Node
@export var battle_manager: BattleManager

func start_random_encounter(encounter_type:DifficultyManager.EncounterType=DifficultyManager.EncounterType.NORMAL):
	if encounter_pools.is_empty():
		push_warning("No encounter pools defined")
		return

	_clear_previous_enemies()

	var pool = difficulty_manager.get_encounter(encounter_type)
	battle_manager.item_drops.clear()
	battle_manager.item_drops.append_array(pool.item_drops)
	_spawn_enemies(pool.enemies)

	battle_manager.set_encounter_type(encounter_type)
	battle_manager.start_battle()

func start_encounter(index:int):
	if encounter_pools.is_empty():
		push_warning("No encounter pools defined")
		return

	_clear_previous_enemies()

	var pool = encounter_pools[index]
	_spawn_enemies(pool.enemies)
	
	battle_manager.start_battle()

func start_unlisted_encounter(index:int):
	if unlisted_encounter_pools.is_empty():
		push_warning("No encounter pools defined")
		return

	_clear_previous_enemies()

	var pool = unlisted_encounter_pools[index]
	_spawn_enemies(pool.enemies)

	battle_manager.start_battle()

func _spawn_enemies(enemies: Array[PackedScene]):
	for scene in enemies:
		var unit := scene.instantiate()
		if not unit is Unit:
			unit.queue_free()
			continue

		unit.is_ally = false
		enemy_parent.add_child(unit)
		unit.add_to_group("Unit")

func _clear_previous_enemies():
	for child in enemy_parent.get_children():
		if child is Unit:
			child.queue_free()
