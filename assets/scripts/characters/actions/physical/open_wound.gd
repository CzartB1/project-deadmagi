class_name OpenWoundAction
extends Action

#@export var base_damage: int = 2

func _init() -> void:
	action_name = "Open Wound"
	description = "Cut into an enemy, causing bleeding. Opposed Agility roll: applies AGI/2 bleed on partial hit, AGI/2 +1 on full hit, or AGI/2 +3 bleed + (STR+2)×2 damage on a crit — also restoring morale equal to damage. Adds Physical modifier to bleed."
	damage_type = damage_types.physical
	target=action_target.enemies_individual

func execute(user: Unit, target:Unit):
	if !target: return
	
	var d = Dice.opposed_roll(10, 
	user.agility-user.status_manager.exhaustion-user.status_manager.suppression, 
	target.agility-target.status_manager.exhaustion-target.status_manager.exhaustion
	)
	var damage = 0
	var bleed = 0
	
	print("[attack] ", str(user.unit_name), " opens a wound on ", str(target.unit_name))
	
	if d == Dice.roll_result.success:
		#damage = user.strength + power
		bleed = 1+user.agility/2
		print("   attack deals ", str(bleed), " bleed")
	elif d == Dice.roll_result.partial_success:
		#damage = int(user.strength + power * 0.5)
		bleed=user.agility/2
		print("   attack deals ", str(bleed), " bleed")
	elif d == Dice.roll_result.partial_fail:
		#damage = int(user.strength + power * 0.25)
		bleed=user.agility/2
		print("   attack deals ", str(bleed), " bleed")
	elif d == Dice.roll_result.fail:
		print("   attack miss")
		return
	elif d == Dice.roll_result.crit:
		damage = int((user.strength + 2) * 2)
		bleed = 3+user.agility/2
		user.receive_morale_damage(-damage)
		print("   attack deals ", str(damage), " damage")
		print("   gained ", str(damage), " morale")
	
	user.model.move_action(target.model.global_position)
	target.status_manager.add_bleed(bleed+user.get_phys_damage_mod())
