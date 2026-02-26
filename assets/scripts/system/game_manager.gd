extends Node

var current_state:game_state=game_state.not_battle

signal battle_composition_changed
signal dialogue_end_next_event
signal dialogue_end_battle_random #TODO add a signal for a specified encounter
signal dialogue_end_battle_unlisted(index:int)
signal dialogue_end_battle(index:int)
signal item_requested(item_scene: PackedScene)
signal random_item_requested(pool:Array[PackedScene])
signal recruit_requested(unit_scene: PackedScene)
signal random_recruit_requested()
signal party_menu_opened
signal party_menu_closed	

enum game_state{
	battle,
	not_battle,
	menu
}

func can_open_party_menu() -> bool:
	return current_state == game_state.not_battle

func give_item_to_party(item_id: String):
	var scene := ItemDatabase.get_item_scene(item_id)
	if scene == null:
		push_error("Invalid item id: %s" % item_id)
		return

	item_requested.emit(scene)

func request_recruit(unit_scene_path: String):
	recruit_requested.emit(load(unit_scene_path))

func request_recruit_random():
	random_recruit_requested.emit()

func request_item_random(pool:Array[PackedScene]=[]):
	random_item_requested.emit(pool)
