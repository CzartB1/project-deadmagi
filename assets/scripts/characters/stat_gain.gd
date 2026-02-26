class_name StatGain
extends Resource

enum Stat {
	strength,
	agility,
	body,
	mind,
	will
}

@export var stat: Stat = Stat.strength
@export var amount: int = 1
