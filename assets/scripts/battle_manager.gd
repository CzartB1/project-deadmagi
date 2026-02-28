extends Node
class_name BattleManager

@export var event_manager: EventManager
@export var economy_manager: EconomyManager  # add this line
@export var turn_delay: float = 1.0
@export var allies: Array[Unit] = []
@export var enemies: Array[Unit] = []

@export_group("UI")
@export var victory_screen: Control
@export var zone_end_screen: Control

@export_group("Lines")
@export var ally_line: FormationLine3D
@export var enemy_line: FormationLine3D
@export var bind_line: FormationLine3D
@export var line_anim_offset:int = 25
@export var line_anim_duration: float = 0.1

@export_group("XP")
@export var xp_normal:  int = 80
@export var xp_elite_mult:  float = 1.5
@export var xp_boss_mult:   float = 2.5
const XP_INACTIVE_FRACTION := 0.5

var turn_queue: Array[Unit] = []
var current_unit: Unit = null
var battle_running := false
var waiting_for_ally_input := false
var item_drops:Array[PackedScene] = []
var _last_encounter_type: DifficultyManager.EncounterType = DifficultyManager.EncounterType.NORMAL

signal battle_started
signal ally_turn_confirmed
signal battle_ended(victory: bool)

func _ready():
	# IMPORTANT: allow UI to process while paused
	if victory_screen:
		victory_screen.process_mode = Node.PROCESS_MODE_ALWAYS

func _setup_ui():
	victory_screen.visible = false

func build_turn_queue():
	turn_queue = allies + enemies
	turn_queue.sort_custom(func(a, b):
		return a.agility > b.agility
	)

func start_battle():
	if battle_running:
		return

	allies.clear()
	enemies.clear()
	#item_drops.clear()
	
	var ally_start_z := ally_line.position.z
	var enemy_start_z := enemy_line.position.z
	ally_line.position.z = ally_start_z + line_anim_offset
	enemy_line.position.z = enemy_start_z - line_anim_offset
	
	for u in get_tree().get_nodes_in_group("Unit"):
		if u is Unit:
			if u.is_ally:
				allies.append(u)
				u.on_battle_start()
			else:
				enemies.append(u)
				#print("[Battle] enemy found: ", u.unit_name, " | item_drop: ", u.item_drop, " | path: ", u.get_path())
			#u.model.reset_model_pos()
	
	
	for u in allies + enemies:
		u.battle_manager=self

	build_turn_queue()
	call_deferred("_setup_ui")

	spawn_units(allies)
	spawn_units(enemies)
	ally_line._reposition_units()
	enemy_line._reposition_units()
	
	
	var lintw := create_tween()
	lintw.tween_property(
		ally_line,
		"position:z",
		ally_start_z,
		line_anim_duration
	)
	lintw.tween_property(
		enemy_line,
		"position:z",
		enemy_start_z,
		line_anim_duration
	)

	await lintw.finished
	ally_line._reposition_units()
	enemy_line._reposition_units()

	battle_running = true
	battle_started.emit()
	GameManager.current_state = GameManager.game_state.battle
	
	await get_tree().create_timer(1.0).timeout
	battle_loop()

func battle_loop():
	while battle_running and GameManager.current_state == GameManager.game_state.battle:
		for unit in turn_queue:
			if not battle_running: return
			if _check_battle_end(): break
			if not is_instance_valid(unit): continue
			
			current_unit = unit
			
			ally_line._reposition_units()
			enemy_line._reposition_units()
			bind_line._reposition_units()
			#unit.model.reset_model_pos()
			
			var alive_allies = allies.filter(is_instance_valid)
			var alive_enemies = enemies.filter(is_instance_valid)

			if unit.is_ally:
				unit.cam_setup()
				if unit.bind_target:
					unit.bind_cam.priority=6
					unit.bind_cam.look_at_targets.clear()
					unit.bind_cam.look_at_targets.append(unit.model.mesh)
					unit.bind_cam.follow_targets.clear()
					unit.bind_cam.follow_targets.append(unit.model.mesh)
					unit.bind_cam.look_at_targets.append(unit.bind_target.model.mesh)
					unit.bind_cam.follow_targets.append(unit.bind_target.model.mesh)
				unit.turn_cam.priority=5
				unit.action_panel._on_turn_started(unit)
				await await_ally_input()
				unit.action_panel._on_turn_ended(unit)
				#unit.panel.ally_controls.visible=false
				if not battle_running: return
				await unit.take_turn(alive_allies, alive_enemies)
				await get_tree().create_timer(.2).timeout
				if is_instance_valid(unit):
					unit.turn_cam.priority=0
					unit.bind_cam.priority=0
					unit.bind_cam.look_at_targets.clear()
			else:
				await get_tree().create_timer(turn_delay).timeout
				if is_instance_valid(unit):
					await unit.take_turn(alive_enemies, alive_allies)
					await get_tree().create_timer(.2).timeout
			
			if is_instance_valid(unit) and is_instance_valid(unit.model): unit.model.reset_model_pos()
			
			if _check_battle_end(): break

func _check_battle_end() -> bool:
	var alive_allies = allies.filter(is_instance_valid)
	var alive_enemies = enemies.filter(is_instance_valid)

	if alive_allies.is_empty():
		_end_battle(false)
		return true

	if alive_enemies.is_empty():
		_end_battle(true)
		return true

	return false

func _end_battle(victory: bool):
	battle_running = false
	waiting_for_ally_input = false
	current_unit = null

	GameManager.current_state = GameManager.game_state.not_battle
	get_tree().paused = false

	battle_ended.emit(victory)

	if victory:
		_on_battle_won()
	else:
		_on_battle_lost()

func _on_battle_won():
	print("BATTLE WON")
	_distribute_xp()
	if event_manager.current_event is EventNode:
		if not item_drops.is_empty():
			event_manager.diff_manager.give_party_random_item(item_drops, _last_encounter_type)
		else:
			event_manager.diff_manager.give_party_random_item([], _last_encounter_type)
		victory_screen.visible = true
	elif event_manager.current_event is BossNode:
		zone_end_screen.visible = true

func _on_battle_lost():
	print("BATTLE LOST")

func spawn_units(units: Array[Unit]):
	for u in units:
		u.bind_line = bind_line
		if u.is_ally:
			ally_line.add_unit(u)
		else:
			enemy_line.add_unit(u)

func await_ally_input():
	waiting_for_ally_input = true
	while waiting_for_ally_input:
		# HARD escape: battle ended while waiting
		if not battle_running:
			break
		# HARD escape: allies/enemies changed while waiting
		if _check_battle_end():
			break
		await get_tree().process_frame
	waiting_for_ally_input = false

func _unhandled_input(event):
	if event.is_action_pressed("confirm_turn") and waiting_for_ally_input:
		waiting_for_ally_input = false

func confirm_turn_button():
	if waiting_for_ally_input:
		waiting_for_ally_input = false

func set_encounter_type(type: DifficultyManager.EncounterType):
	_last_encounter_type = type

func _distribute_xp():
	var context := event_manager.diff_manager.get_context()
	var loop_mult: float = context.get("loop_multiplier", 1.0)

	var base_xp := xp_normal
	match _last_encounter_type:
		DifficultyManager.EncounterType.ELITE:
			base_xp = int(xp_normal * xp_elite_mult)
		DifficultyManager.EncounterType.BOSS:
			base_xp = int(xp_normal * xp_boss_mult)

	var full_xp    := int(base_xp * loop_mult)
	var partial_xp := int(full_xp * XP_INACTIVE_FRACTION)

	for u in allies:
		if not is_instance_valid(u):
			continue
		var award := full_xp if u.has_acted else partial_xp
		u.gain_xp(award)
		print("[xp] %s receives %d XP (acted=%s)" % [u.unit_name, award, u.has_acted])
