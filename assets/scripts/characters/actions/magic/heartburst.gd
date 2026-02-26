class_name HeartburstAction
extends Action

func _init() -> void:
	action_name = "Heartburst"
	description = "Rupture an enemy's veins using their own bleed. Deals bleed × 0.8 × (1 + 0.04 × (Mind−5)) damage and consumes all bleed. Doubled on crit, also restoring morale equal to damage. If target has no bleed, you take half the damage instead (quarter on crit). Mind vs. lower of target Mind/Body. Adds Magic modifier."
	damage_type = damage_types.magic
	target=action_target.enemies_individual

func execute(user: Unit, target:Unit):
	if !target: return
	
	var d = Dice.opposed_roll(10, 
	user.mind-user.status_manager.exhaustion-user.status_manager.suppression, 
	min(target.mind,target.body)-target.status_manager.exhaustion-target.status_manager.exhaustion
	)
	var damage = 0
	var s_damage=0
	user.model.move_action(target.model.global_position)
	
	print("[attack] ", str(user.unit_name), " bursts ", str(target.unit_name), "'s heart")
	
	if d == Dice.roll_result.crit:
		damage = ceili(target.status_manager.bleed * 0.8 * (1 + 0.04 * max((user.mind - 5),1))*2)
		user.receive_morale_damage(-damage)
		s_damage=floori(damage/4)
		print("   attack deals ", str(damage), " damage")
		print("   gained ", str(damage), " morale")
	else: 
		damage = ceili(target.status_manager.bleed * 0.8 * (1 + 0.04 * max((user.mind - 5),1)))
		s_damage=ceili(damage/2)
		print("   attack deals ", str(damage), " damage")
	
	if target.status_manager.bleed>0:target.status_manager.bleed=0
	else: user.receive_damage(s_damage)
	target.status_manager.status_update.emit()
	target.receive_damage(damage+user.get_magic_damage_mod())
