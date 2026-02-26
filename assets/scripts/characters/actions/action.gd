class_name Action
extends Resource

enum action_target{all, enemies_individual, enemies_group, allies_individual, allies_group, user}
enum damage_types{physical, magic, tech}

var action_name: String = "Attack"
var description: String = "Lorem Ipsum"
var target: action_target=action_target.all
var damage_type: damage_types=damage_types.physical

@export var base_cooldown: int = 0

func execute(user: Unit, target:Unit):
	# Override in subclasses
	pass
