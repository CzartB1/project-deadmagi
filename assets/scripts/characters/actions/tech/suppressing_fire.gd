class_name SuppressingFireAction
extends Action

@export var power: int = 2

func _init() -> void:
	action_name = "Suppressing Fire"
	description = "Lay fire on a single enemy. Deals no direct damage, but applies 1–3 suppression on hit, or 5 on a crit. Hits also deal 3–5 morale damage. Opposed Agility roll."
	damage_type = damage_types.tech
	target=action_target.enemies_individual

func execute(user: Unit, target:Unit):
	if !target: return
	
	var d = Dice.opposed_roll(10, 
	user.agility-user.status_manager.exhaustion-user.status_manager.suppression, 
	target.agility-target.status_manager.exhaustion-target.status_manager.exhaustion
	)
	var damage = 0
	var suppression = 0
	
	print("[attack] ", str(user.unit_name), " supresses ", str(target.unit_name))
	
	if d == Dice.roll_result.success:
		#damage = user.strength + power
		suppression = 3
		target.receive_morale_damage(3)
		print("   attack deals ", str(suppression), " supress")
	elif d == Dice.roll_result.partial_success:
		#damage = int(user.strength + power * 0.5)
		suppression=2
		target.receive_morale_damage(3)
		print("   attack deals ", str(suppression), " supress")
	elif d == Dice.roll_result.partial_fail:
		#damage = int(user.strength + power * 0.25)
		suppression=1
		print("   attack deals ", str(suppression), " supress")
	elif d == Dice.roll_result.fail:
		print("   attack miss")
		return
	elif d == Dice.roll_result.crit:
		suppression = 5
		target.receive_morale_damage(5)
		print("   attack deals ", str(damage), " supress")
		#print("   gained ", str(damage), " morale")
	
	#user.model.move_action(target.model.global_position)
	target.status_manager.add_suppression(suppression+user.get_tech_damage_mod())
