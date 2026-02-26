class_name ProtectAction
extends Action

func _init() -> void:
	action_name = "Protect"
	description = "Step in front of an ally, intercepting all damage dealt to them. Lasts 3 turns, or 5 on a crit. Will roll determines crit chance. Breaks on bind.Step in front of an ally, intercepting all damage dealt to them. Lasts 3 turns, or 5 on a crit. Will roll determines crit chance. Breaks on bind."
	target = action_target.allies_individual

func execute(user: Unit, target:Unit):
	if !target: return
	if target.is_ally!=user.is_ally:
		print("[attack] ", str(user.unit_name)," tries to protect an enemy and realizes the stupidity of it")
		return
	
	user.model.move_action(target.model.global_position)
	
	var a = Dice.opposed_roll(10,user.will)
	var pt=0
	
	if a==Dice.roll_result.crit: pt=5
	else: pt=3
	
	print("[attack] ", str(user.unit_name), " protects ", str(target.unit_name))
	
	user.model.move_action(target.model.global_position)
	target.add_protector(user,pt)
