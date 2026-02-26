class_name Item
extends Node

@export var item_name: String
@export var description: String
@export var slot_cost: int = 1
@export var priority: int = 0

# Optional stat modifiers
@export var strength_bonus := 0
@export var mind_bonus := 0
@export var agility_bonus := 0
@export var body_bonus := 0
@export var will_bonus := 0

# Optional actions granted by this item
@export var granted_actions: Array[Action] = []
@export var granted_bind_actions: Array[Action] = []

var wielder: Unit = null

func on_equip(unit: Unit):
	wielder=unit
	#unit.action_manager.add_item_actions(self)

func on_unequip(unit: Unit):
	wielder=null
	#unit.action_manager.remove_item_actions(self)
