extends Node

signal blurb_selected(intent: Dictionary)

@export var global_cooldown := 1.5
@export var collect_window := 0.2

var _cooldown := false
var _collecting := false
var _intent_buffer: Array = []
var _speaker_cooldowns := {}

func submit_blurb_intent(intent: Dictionary) -> void:
	print("[blurb] submit intent")
	if _cooldown:
		return

	_intent_buffer.append(intent)

	if not _collecting:
		_start_collection_window()


func _start_collection_window() -> void:
	_collecting = true
	await get_tree().create_timer(collect_window).timeout
	_collecting = false
	_resolve_intents()


func _resolve_intents() -> void:
	if _intent_buffer.is_empty():
		return
	print("[blurb] resolving intent")
	var chosen := _pick_intent(_intent_buffer)
	_intent_buffer.clear()

	if chosen:
		_play_blurb(chosen)
		_start_global_cooldown()


func _pick_intent(intents: Array) -> Dictionary:
	intents.sort_custom(_compare_priority)
	for intent in intents:
		if not _speaker_on_cooldown(intent.speaker):
			return intent
	return intents[0]


func _compare_priority(a: Dictionary, b: Dictionary) -> bool:
	return _priority(a.event) > _priority(b.event)


func _priority(event: String) -> int:
	match event:
		"defeated": return 100
		"ally_defeated": return 80
		"morale_change": return 70
		"damage_taken": return 60
		"ability_used": return 40
		_: return 10


func _speaker_on_cooldown(speaker_id) -> bool:
	return _speaker_cooldowns.get(speaker_id, 0) > Time.get_ticks_msec()

func _play_blurb(intent: Dictionary) -> void:
	_speaker_cooldowns[intent.speaker] = Time.get_ticks_msec() + 3000
	print("[blurb] playing blurb")
	emit_signal("blurb_selected", intent)


func _start_global_cooldown() -> void:
	_cooldown = true
	await get_tree().create_timer(global_cooldown).timeout
	_cooldown = false
