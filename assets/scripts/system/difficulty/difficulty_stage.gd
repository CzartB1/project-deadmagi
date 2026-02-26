class_name DifficultyStage
extends Resource

@export var id: String
var display_name: String

@export var enemy_pools: Array[EncounterPool]          # Array[EnemyEncounterPool]
@export var elite_pools: Array[EncounterPool]         # Array[EnemyEncounterPool]
@export var boss_pools: Array[EncounterPool]          # Array[EnemyEncounterPool]

@export var event_pools: Array[DialogueResource]        # Array[EventPool]
@export var item_pools: Array[PackedScene]        # fill w item_node.

@export var recruit_pool:Array[PackedScene]       # fill w units

@export var modifiers: Dictionary    # arbitrary flags / numbers
@export var is_terminal := false
