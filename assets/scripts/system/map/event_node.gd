class_name EventNode
extends MapNode

@export var length:int=3

var events:Array[Event]
var current_event:Event
var cur_ev_id:int=0
var cur_d:Node

func _ready():
	super._ready()
	events.resize(length)
	#GameManager.next_event.connect(dialogue_end)
	for i in range(length):
		var e =Event.new()
		var r = randi_range(0,1) #TODO edit this
		if r==0: 
			e.type=e.eventType.battle
			text=text+"[B]"
		elif r==1: 
			e.type=e.eventType.random
			text=text+"[R]"
		elif r==2: 
			e.type=e.eventType.shop
			text=text+"[S]"
		events[i] = e

func _pressed(): 
	super._pressed()
	do_event()

func do_event():
	if events[cur_ev_id].type==Event.eventType.battle:
		manager.start_battle()
		manager.battle_manager.battle_ended.connect(next_event, CONNECT_ONE_SHOT)
	elif events[cur_ev_id].type==Event.eventType.shop:
		print("shop")
		next_event()
	elif events[cur_ev_id].type==Event.eventType.random:
		#if not DialogueManager.dialogue_ended.is_connected(dialogue_end):
			#DialogueManager.dialogue_ended.connect(dialogue_end, CONNECT_ONE_SHOT)
		GameManager.dialogue_end_next_event.connect(dialogue_end,CONNECT_ONE_SHOT)
		GameManager.dialogue_end_battle_random.connect(dialogue_end_battle,CONNECT_ONE_SHOT)
		GameManager.dialogue_end_battle_unlisted.connect(dialogue_end_battle_specific_unlisted,CONNECT_ONE_SHOT)
		GameManager.dialogue_end_battle.connect(dialogue_end_battle_specific,CONNECT_ONE_SHOT)

		cur_d = DialogueManager.show_dialogue_balloon(manager.diff_manager._get_event())
		#next_event()

func dialogue_end():
	if cur_d: cur_d.queue_free()
	GameManager.dialogue_end_battle_random.disconnect(dialogue_end_battle)
	GameManager.dialogue_end_battle_unlisted.disconnect(dialogue_end_battle_specific_unlisted)
	GameManager.dialogue_end_battle.disconnect(dialogue_end_battle_specific)
	print("end")
	await get_tree().process_frame
	next_event()

func dialogue_end_battle():
	manager.start_battle()
	manager.battle_manager.battle_ended.connect(next_event, CONNECT_ONE_SHOT)
	GameManager.dialogue_end_next_event.disconnect(dialogue_end)
	GameManager.dialogue_end_battle_unlisted.disconnect(dialogue_end_battle_specific_unlisted)
	GameManager.dialogue_end_battle.disconnect(dialogue_end_battle_specific)

func dialogue_end_battle_specific(index:int):
	manager.start_battle(true, index)
	manager.battle_manager.battle_ended.connect(next_event, CONNECT_ONE_SHOT)
	GameManager.dialogue_end_next_event.disconnect(dialogue_end)
	GameManager.dialogue_end_battle_unlisted.disconnect(dialogue_end_battle_specific_unlisted)
	GameManager.dialogue_end_battle_random.disconnect(dialogue_end_battle)

func dialogue_end_battle_specific_unlisted(index:int):
	manager.start_battle(true, index, true)
	manager.battle_manager.battle_ended.connect(next_event, CONNECT_ONE_SHOT)
	GameManager.dialogue_end_next_event.disconnect(dialogue_end)
	GameManager.dialogue_end_battle_random.disconnect(dialogue_end_battle)
	GameManager.dialogue_end_battle.disconnect(dialogue_end_battle_specific)

func next_event():
	print("[event node] change event")
	cur_ev_id+=1
	if cur_ev_id<length: 
		print("[event node] event string incomplete")
		do_event()
	else: 
		print("[event node] event string complete")
		complete()
