extends Node

var items := {
	#"relic_black_spine": preload("res://items/black_spine.tscn"),
	#"servo_torc": preload("res://items/servo_torc.tscn"),
	"sprint_boots": preload("res://assets/scenes/characters/item/item_sprinting_boot.tscn"),
	"ballistic_plate": preload("res://assets/scenes/characters/item/item_ballistic_plate.tscn")
}

func get_item_scene(item_id: String) -> PackedScene:
	if not items.has(item_id):
		push_error("[ItemDatabase] unknown item id '%s'" % item_id)
		return null
	return items[item_id]

func has_item(item_id: String) -> bool:
	return items.has(item_id)

func get_all_item_ids() -> Array[String]:
	return items.keys()
