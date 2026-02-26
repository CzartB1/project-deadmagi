class_name BossNode
extends MapNode

@export var boss_encounter_pools: Array[EncounterPool] = []
@export var enemy_parent: Node
@export var battle_manager: BattleManager
@export var diff_manager: DifficultyManager

func _pressed(): 
	super._pressed()
	start_random_encounter()

func _clear_previous_enemies():
	for child in enemy_parent.get_children():
		if child is Unit:
			child.queue_free()

func start_random_encounter():
	if boss_encounter_pools.is_empty():
		push_warning("No encounter pools defined")
		return

	_clear_previous_enemies()

	var pool = diff_manager.get_encounter(DifficultyManager.EncounterType.BOSS)
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
