extends Node
class_name UnitBlurbManager

@export var unit: Unit

## --- Blurb pools ---
@export var damage_taken_blurbs: Array[String] = []
@export var morale_damage_blurbs: Array[String] = []
#TODO add more dialogue types

func _ready():
	#unit.spawned.connect(_on_spawned)
	unit.damaged.connect(_on_damage_taken)
	unit.morale_damaged.connect(_on_morale_damaged)
	#unit.ability_used.connect(_on_ability_used)
	#unit.ally_defeated.connect(_on_ally_defeated)
	#unit.defeated.connect(_on_defeated)

func _on_damage_taken(context := {}):
	_submit("damage_taken", damage_taken_blurbs, context)

func _on_morale_damaged(context := {}):
	_submit("morale_change", morale_damage_blurbs, context)

func _submit(event: String, pool: Array[String], context := {}):
	if pool.is_empty() or !unit.is_ally:
		return

	var blurb_text = pool.pick_random()
	#var blurb_text = "fadjmino"

	var intent := {
		"speaker": unit.name+"_"+unit.unit_name,
		"event": event,
		"text": blurb_text,
		"context": context
	}

	BlurbDirector.submit_blurb_intent(intent)
