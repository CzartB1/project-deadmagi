class_name FearHarvestAction
extends Action

func _init() -> void:
	target=action_target.enemies_individual
	damage_type=damage_types.magic
	description="Feed on an enemy's fear. Deals 1 + 3–8×missing morale on hit, or 1 + 12×missing morale on a crit — also restoring morale equal to damage. Opposed Agility roll. Adds Magic modifier."

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
		damage = 1+8*(target.max_morale-target.current_morale)
		print("   attack deals ", str(damage), " damage")
	elif d == Dice.roll_result.partial_success:
		damage = 1+6*(target.max_morale-target.current_morale)
		print("   attack deals ", str(damage), " damage")
	elif d == Dice.roll_result.partial_fail:
		damage = 1+3*(target.max_morale-target.current_morale)
		print("   attack deals ", str(damage), " damage")
	elif d == Dice.roll_result.fail:
		print("   attack miss")
		user.model.move_action(target.model.global_position)
		return
	elif d == Dice.roll_result.crit:
		damage = 1+12*(target.max_morale-target.current_morale)
		user.receive_morale_damage(-damage)
		zoom=true
		print("   attack deals ", str(damage), " damage")
		print("   gained ", str(damage), " morale")
	
	user.model.move_action(target.model.global_position, zoom)
	target.receive_damage(damage+user.get_magic_damage_mod())
