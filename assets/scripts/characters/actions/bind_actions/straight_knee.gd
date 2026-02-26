class_name SKneeAction
extends Action

@export var power: int = 2

func _init() -> void:
	action_name = "Straight Knee"
	description = "Strike with a rising knee. AGI + dominance vs. target AGI − dominance. Full hit deals STR+2 + stun. Partial hit deals STR/2+2. Crit deals STR+2 + stun + 1 exhaustion to target. Adds Physical modifier. Dominance on both sides directly shifts the roll."
	damage_type = damage_types.physical
	target=action_target.enemies_individual

func execute(user: Unit, target:Unit):
	if !target: return
	
	var d = Dice.opposed_roll(8, 
	user.agility+user.dominance-user.status_manager.exhaustion-user.status_manager.suppression, 
	target.agility-target.dominance-target.status_manager.exhaustion-target.status_manager.exhaustion
	)
	var damage = 0
	user.model.move_action(target.model.global_position)
	
	print("[attack] ", str(user.unit_name), " attacks ", str(target.unit_name))
	
	if d == Dice.roll_result.success:
		damage = user.strength + power
		target.status_manager.add_stun(1)
		print("   attack deals ", str(damage), " damage")
	elif d == Dice.roll_result.partial_success:
		damage = user.strength/2 + power
		print("   attack deals ", str(damage), " damage")
	elif d == Dice.roll_result.partial_fail:
		damage = int(user.strength/2 + power * 0.25)
		print("   attack deals ", str(damage), " damage")
	elif d == Dice.roll_result.fail:
		print("   attack blocked")
		return
	elif d == Dice.roll_result.crit:
		damage = user.strength + power
		target.status_manager.add_stun(1)
		target.status_manager.exhaustion+=1
		print("   attack deals ", str(damage), " damage")
		print("   gained ", str(damage), " morale")
	
	target.receive_damage(damage+user.get_phys_damage_mod())
