class_name InspireAction
extends Action

func _init() -> void:
	action_name = "Inspire"
	description="Bolster an ally's resolve. Restores ⌈1 + 0.07 × (Mind−5)⌉ morale, doubled on crit. Crit also restores morale to the user equal to half the Magic modifier. Uncontested Mind roll. Adds Magic modifier."
	damage_type = damage_types.magic
	target=action_target.allies_individual

func execute(user: Unit, target:Unit):
	if !target: return
	
	var d = Dice.opposed_roll(10, 
	user.mind-user.status_manager.exhaustion-user.status_manager.suppression
	)
	var heal = 0
	user.model.move_action(target.model.global_position)
	
	print("[attack] ", str(user.unit_name), " absorbs ", str(target.unit_name), "'s bleed")
	
	if d == Dice.roll_result.crit:
		heal = ceili((1 + 0.07 * max((user.mind - 5),1))*2)
		user.receive_morale_damage(-heal+user.get_magic_damage_mod()/2)
		print("   attack heals ", str(heal), "morale")
		print("   gained ", str(heal), " morale")
	else: 
		heal = ceili((1 + 0.07 * max((user.mind - 5),1)))
		print("   attack heals ", str(heal), "morale")
	
	target.status_manager.status_update.emit()
	target.receive_morale_damage(-heal+user.get_magic_damage_mod())
