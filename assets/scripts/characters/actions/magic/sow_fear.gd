class_name SowFearAction
extends Action

#@export var power: int = 5

func _init() -> void:
	action_name = "Sow Fear"
	description = "Spread fear across the entire enemy line. Deals 1–3 morale damage per enemy on hit, or 6 on a crit. Each enemy rolls separately. Mind vs. each target's Will. Adds Magic modifier."
	target = action_target.enemies_group
	damage_type = damage_types.magic

func execute(user: Unit, target:Unit):
	if !target: return
	
	#var shot=Dice.opposed_roll(6, user.agility, user.status_manager.suppression)
	#var att = 3
	#if shot==Dice.roll_result.crit: att=5
	
	var units = user.get_tree().get_nodes_in_group("Unit")
	print("[attack] ", str(user.unit_name), " sows fear")
	
	for i in units.filter(func(u:Unit): return u.is_ally!=user.is_ally):
		#for j in range(att):
		var d = Dice.opposed_roll(8, 
		user.mind-user.status_manager.exhaustion-user.status_manager.suppression, 
		i.will-i.status_manager.exhaustion-i.status_manager.suppression
		)
		var damage = 0
		#var zoom=false
		
		
		if d == Dice.roll_result.success:
			damage = 3
			print("   attack deals ", str(damage), " damage")
		elif d == Dice.roll_result.partial_success:
			damage = 2
			print("   attack deals ", str(damage), " damage")
		elif d == Dice.roll_result.partial_fail:
			damage = 1
			print("   attack deals ", str(damage), " damage")
		elif d == Dice.roll_result.fail:
			print("   attack fails")
		elif d == Dice.roll_result.crit:
			damage = 6
			print("   attack deals ", str(damage), " damage")
			#print("   gained ", str(damage), " morale")
		
		#user.model.move_action(target.model.global_position, zoom)
		if i is Unit: 
			i.receive_morale_damage(damage+user.get_magic_damage_mod())
			i.morale_check()
