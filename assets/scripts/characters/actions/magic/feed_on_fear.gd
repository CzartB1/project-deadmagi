class_name FeedFearAction
extends Action

func _init() -> void:
	action_name = "Feed on Fear"
	description = "Siphon an enemy's fear as life force. Heals 1 + 2× target's missing morale, or 1 + 5× on a crit. Healing is also dealt as morale damage to the target. Mind vs. lower of target's Mind/Body. Adds Magic modifier."
	damage_type = damage_types.magic
	target=action_target.enemies_individual

func execute(user: Unit, target:Unit):
	if !target: return
	
	var d = Dice.opposed_roll(10, 
		user.mind-user.status_manager.exhaustion-user.status_manager.suppression, 
		min(target.mind,target.body)-target.status_manager.exhaustion-target.status_manager.exhaustion
	)
	var heal = 0
	user.model.move_action(target.model.global_position)
	
	print("[attack] ", str(user.unit_name), " absorbs ", str(target.unit_name), "'s morale")
	
	if d == Dice.roll_result.crit:
		heal = 1+5*(target.max_morale-target.current_morale)
		print("   attack heals ", str(heal))
		print("   gained ", str(heal), " morale")
	else: 
		heal = 1+2*(target.max_morale-target.current_morale)
		print("   attack heals ", str(heal))
	
	heal+=user.get_magic_damage_mod()
	target.receive_morale_damage(heal)
	target.status_manager.status_update.emit()
	user.receive_damage(-heal)
