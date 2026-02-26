class_name SlugshotAction
extends Action

@export var power: int = 5

func _init() -> void:
	target=action_target.enemies_individual
	action_name = "Slugshot"
	description = "Fire a slug at an enemy. Hits are always stunning. Deals 7–12 tech damage on hit, or 25 on a critical — also restoring 25 morale. Opposed Agility roll."
	damage_type = damage_types.tech

func execute(user: Unit, target:Unit):
	if !target: return
	
	var d = Dice.opposed_roll(10, 
	user.agility-user.status_manager.exhaustion-user.status_manager.suppression, 
	target.agility-target.status_manager.exhaustion-target.status_manager.exhaustion
	)
	var damage = 0
	var zoom=false
	
	print("[attack] ", str(user.unit_name), " attacks ", str(target.unit_name), " with a slugshot")
	
	if d == Dice.roll_result.success:
		damage = 12
		target.status_manager.add_stun(1)
		print("   attack deals ", str(damage), " damage")
	elif d == Dice.roll_result.partial_success:
		damage = 7
		target.status_manager.add_stun(1)
		print("   attack deals ", str(damage), " damage")
	elif d == Dice.roll_result.partial_fail:
		target.status_manager.add_stun(1)
		print("   attack deals ", str(damage), " damage")
	elif d == Dice.roll_result.fail:
		print("   attack miss")
		#user.model.move_action(target.model.global_position)
		return
	elif d == Dice.roll_result.crit:
		damage = 25
		target.status_manager.add_stun(2)
		user.receive_morale_damage(-damage)
		zoom=true
		print("   attack deals ", str(damage), " damage")
		print("   gained ", str(damage), " morale")
	
	#user.model.move_action(target.model.global_position, zoom)
	target.receive_damage(damage+user.get_tech_damage_mod())
