class_name RageAction
extends Action

func _init() -> void:
	target=action_target.user
	action_name = "Rage"
	description = "Enter a battle rage, gaining 3 rage to boost physical damage. Crit grants 5 rage + 2 morale. On a fail, gain 2 exhaustion instead. Will + Strength roll vs. own Exhaustion."

func execute(user: Unit, target:Unit):
	if !target: return
	
	var d = Dice.opposed_roll(10, 
	user.will+user.strength, 
	user.status_manager.exhaustion
	)
	var rage = 0
	
	print("[attack] ", str(user.unit_name), " rages.")
	
	if d == Dice.roll_result.crit:
		rage = 5
		user.receive_morale_damage(-rage/2)
		print("   gained ", str(rage), " rage")
	else: 
		rage = 3
		print("   gained ", str(rage), " rage")
		if d == Dice.roll_result.fail:
			user.status_manager.add_exhaustion(2)
			print("   gained ", str(1), " exhaustion")
	
	user.status_manager.add_rage(rage)
	user.status_manager.status_update.emit()
	#user.receive_damage(-heal)
