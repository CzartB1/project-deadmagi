class_name RecklessAttackAction
extends Action

@export var base: int = 5

func _init() -> void:
	action_name = "Reckless Attack"
	description = "A wild, powerful strike. Deals 2×STR + 5 on hit, or (STR+5)×2 on a crit — restoring morale equal to damage. Uses the higher of AGI or STR. After hitting, roll Will + Body vs. own Exhaustion: fail adds 2 exhaustion, partial fail adds 1. Adds Physical modifier to damage."
	damage_type = damage_types.physical
	target=action_target.enemies_individual

func execute(user: Unit, target:Unit):
	if !target: return
	
	var d = Dice.opposed_roll(10, 
	max(user.agility, user.strength)-user.status_manager.exhaustion-user.status_manager.suppression, 
	target.agility-target.status_manager.exhaustion-target.status_manager.exhaustion
	)
	var damage = 0
	var zoom=false
	
	print("[attack] ", str(user.unit_name), " attacks ", str(target.unit_name))
	
	if d == Dice.roll_result.success:
		damage = 2*user.strength + base
		print("   attack deals ", str(damage), " damage")
	elif d == Dice.roll_result.partial_success:
		damage = int(2*user.strength + base)
		print("   attack deals ", str(damage), " damage")
	elif d == Dice.roll_result.partial_fail:
		damage = int(2*user.strength + base * 0.5)
		print("   attack deals ", str(damage), " damage")
	elif d == Dice.roll_result.fail:
		print("   attack miss")
		user.model.move_action(target.model.global_position)
		return
	elif d == Dice.roll_result.crit:
		damage = ceili((user.strength + base) * 2)
		user.receive_morale_damage(-damage)
		print("   attack deals ", str(damage), " damage")
		print("   gained ", str(damage), " morale")
	
	user.model.move_action(target.model.global_position, zoom)
	target.receive_damage(damage+user.get_phys_damage_mod())
	
	var exh=Dice.opposed_roll(12,
	user.will+user.body,
	user.status_manager.exhaustion)
	match exh:
		Dice.roll_result.fail:
			user.status_manager.add_exhaustion(2)
		Dice.roll_result.partial_fail:
			user.status_manager.add_exhaustion(1)
