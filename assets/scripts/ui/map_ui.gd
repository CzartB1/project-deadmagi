class_name MapUI
extends Control

@export var diff_manager: DifficultyManager
var map_nodes:Array[MapNode]

func _ready() -> void:
	var m = get_tree().get_nodes_in_group("MapNode")
	for n in m: if n is MapNode: map_nodes.append(n)
	if map_nodes.is_empty():
		print("[map ui] map_nodes IS EMPTY")

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("debug_reset_map"): reset()

func reset():
	for m in map_nodes:
		m.refresh()

func loop():
	diff_manager._increase_difficulty(1)
	reset()
