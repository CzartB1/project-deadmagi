class_name EventManager
extends Node2D

@export var battle_manager:BattleManager
@export var encounter_manager:RandomEncounterManager
@export var diff_manager:DifficultyManager
@export var victory_screen: Control
@export var zone_end_screen: Control
@export var random_events: Array[DialogueResource]
@export var map_ui:MapUI
@export var unit_parent:Node
@export var party_manager:PartyManager
var current_event:MapNode
var nodes:Array[MapNode]

func _ready():
	GameManager.recruit_requested.connect(_recruit_unit)
	GameManager.random_recruit_requested.connect(_recruit_random_unit)

func _process(delta):
	if nodes.size()==0:
		var t = get_tree().get_nodes_in_group("MapNode")
		for l in t:
			if l is MapNode and !nodes.has(l):
				nodes.append(l)
				l.manager=self
	if Input.is_action_just_pressed("cheat_god_mode"):
		for i in get_tree().get_nodes_in_group("Unit"):
			if i is Unit and i.is_ally:
				i.god_mode=!i.god_mode
				print("[event manager] god mode enabled: ", str(i.god_mode))

func start_battle(specific:bool=false ,index:int=0, unlisted:bool=false):
	randomize()
	if !specific: encounter_manager.start_random_encounter()
	else: 
		if unlisted: encounter_manager.start_unlisted_encounter(index)
		else: encounter_manager.start_encounter(index)

func next_event():
	victory_screen.visible=false
	zone_end_screen.visible=false
	if current_event is EventNode:
		current_event.next_event()
	elif current_event is BossNode:
		map_ui.loop()
		current_event.complete()

func next_zone():
	zone_end_screen.visible=false
	if current_event is BossNode:
		map_ui.loop()
		diff_manager.advance_zone()
		current_event.complete()

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
