# NameGenerator.gd
# Godot 4.x
# Expects three text files with one name per line:
# - res://names/male.txt
# - res://names/female.txt
# - res://names/nickname.txt

extends Node

const MALE_PATH := "res://names/male.txt"
const FEMALE_PATH := "res://names/female.txt"
const NICKNAME_PATH := "res://names/nickname.txt"

var _male_names: PackedStringArray = []
var _female_names: PackedStringArray = []
var _nicknames: PackedStringArray = []

func _ready() -> void:
	_male_names = _load_names(MALE_PATH)
	_female_names = _load_names(FEMALE_PATH)
	_nicknames = _load_names(NICKNAME_PATH)

func get_male_name() -> String:
	return _pick_random(_male_names)

func get_female_name() -> String:
	return _pick_random(_female_names)

func get_nickname() -> String:
	return _pick_random(_nicknames)

func _load_names(path: String) -> PackedStringArray:
	if not FileAccess.file_exists(path):
		push_error("Name file not found: %s" % path)
		return []

	var file := FileAccess.open(path, FileAccess.READ)
	var names: PackedStringArray = []

	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line.is_empty() or line.begins_with("#"):
			continue
		names.append(line)

	return names

func _pick_random(list: PackedStringArray) -> String:
	if list.is_empty():
		return ""
	return list[randi() % list.size()]
