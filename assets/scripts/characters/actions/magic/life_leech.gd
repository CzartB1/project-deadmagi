class_name LifeleechAction
extends Action

func _init() -> void:
	action_name = "Life Leech"
	description = "Siphon an enemy's blood directly into yourself. Heals ⌈bleed × 0.6 × (1 + 0.07 × (Mind−5))⌉, doubled on crit. Crit also restores morale equal to half the heal. Always consumes all target bleed. Mind vs. lower of target Mind/Body. Adds Magic modifier."
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
	
	print("[attack] ", str(user.unit_name), " absorbs ", str(target.unit_name), "'s bleed")
	
	if d == Dice.roll_result.crit:
		heal = ceili(target.status_manager.bleed * 0.6 * (1 + 0.07 * max((user.mind - 5),1))*2)
		user.receive_morale_damage(-heal/2)
		print("   attack heals ", str(heal))
		print("   gained ", str(heal), " morale")
	else: 
		heal = ceili(target.status_manager.bleed * 0.6 * (1 + 0.07 * max((user.mind - 5),1)))
		print("   attack heals ", str(heal))
	
	target.status_manager.bleed=0
	target.status_manager.status_update.emit()
	user.receive_damage(-heal+user.get_magic_damage_mod())
