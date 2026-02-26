class_name AttackAction
extends Action

@export var power: int = 5

func _init() -> void:
	target=action_target.enemies_individual
	description="A basic strike against one enemy. Opposed Agility roll: deals STR + 25–100% of power on hit, or STR + 2× power on a crit — also restoring morale equal to damage dealt. Adds Physical modifier."

func execute(user: Unit, target:Unit):
	if !target: return
	
	var d = Dice.opposed_roll(10, 
	user.agility-user.status_manager.exhaustion-user.status_manager.suppression, 
	target.agility-target.status_manager.exhaustion-target.status_manager.exhaustion
	)
	var damage = 0
	var zoom=false
	
	print("[attack] ", str(user.unit_name), " attacks ", str(target.unit_name))
	
	if d == Dice.roll_result.success:
		damage = user.strength + power
		print("   attack deals ", str(damage), " damage")
	elif d == Dice.roll_result.partial_success:
		damage = int(user.strength + power * 0.5)
		print("   attack deals ", str(damage), " damage")
	elif d == Dice.roll_result.partial_fail:
		damage = int(user.strength + power * 0.25)
		print("   attack deals ", str(damage), " damage")
	elif d == Dice.roll_result.fail:
		print("   attack miss")
		user.model.move_action(target.model.global_position)
		return
	elif d == Dice.roll_result.crit:
		damage = ceili(user.strength + power * 2)
		user.receive_morale_damage(-damage)
		zoom=true
		print("   attack deals ", str(damage), " damage")
		print("   gained ", str(damage), " morale")
	
	user.model.move_action(target.model.global_position, zoom)
	target.receive_damage(damage+user.get_phys_damage_mod())
