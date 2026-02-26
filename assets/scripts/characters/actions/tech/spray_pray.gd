class_name SprayNPrayAction
extends Action

#@export var power: int = 5

func _init() -> void:
	action_name = "Spray and Pray"
	description = "Fire wildly at every enemy. Always deals at least 1 tech damage. Deals 2–4 on a hit, or 4 + suppression on a crit. Opposed Agility roll per target."
	target = action_target.enemies_group
	damage_type = damage_types.tech

func execute(user: Unit, target:Unit):
	if !target: return
	
	#var shot=Dice.opposed_roll(6, user.agility, user.status_manager.suppression)
	#var att = 3
	#if shot==Dice.roll_result.crit: att=5
	
	var units = user.get_tree().get_nodes_in_group("Unit")
	
	for i in units.filter(func(u:Unit): return u.is_ally!=user.is_ally):
		#for j in range(att):
		var d = Dice.opposed_roll(8, 
		user.agility-user.status_manager.exhaustion-user.status_manager.suppression, 
		i.agility-i.status_manager.exhaustion-i.status_manager.suppression
		)
		var damage = 0
		#var zoom=false
		
		print("[attack] ", str(user.unit_name), " sprays at ", str(i.unit_name))
		
		if d == Dice.roll_result.success:
			damage = 4
			print("   attack deals ", str(damage), " damage")
		elif d == Dice.roll_result.partial_success:
			damage = 3
			print("   attack deals ", str(damage), " damage")
		elif d == Dice.roll_result.partial_fail:
			damage = 2
			print("   attack deals ", str(damage), " damage")
		elif d == Dice.roll_result.fail:
			print("   attack grazes and deals ", str(damage), " damage")
			#user.model.move_action(target.model.global_position)
			damage = 1
		elif d == Dice.roll_result.crit:
			damage = 4
			i.status_manager.add_suppression(1)
			print("   attack deals ", str(damage), " damage")
			#print("   gained ", str(damage), " morale")
		
		#user.model.move_action(target.model.global_position, zoom)
		i.receive_damage(damage+user.get_tech_damage_mod())
