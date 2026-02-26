# ItemManager.gd
# TODO: REMOVE TS CUZ GAME MANAGER HAVE STUFF THAT DOES THE SAME THING
class_name ItemManager
extends Node

signal request_item_ui(item_scene: PackedScene)

func give_item_to_party(item_id: String):
	if not ItemDatabase.has_item(item_id):
		push_error("Invalid item ID: %s" % item_id)
		return

	var scene := ItemDatabase.get_item_scene(item_id)
	request_item_ui.emit(scene)
