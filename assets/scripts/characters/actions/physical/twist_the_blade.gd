class_name TwistTheBladeAction
extends Action

@export var power: int = 2

func _init() -> void:
	action_name = "Twist The Blade"
	description = "Dig into an existing wound. Partial hit deals STR+1 damage and doubles bleed. Full hit deals STR+2 + doubles bleed + adds AGI/2 bleed. Crit deals STR+4 + triples bleed + adds AGI/2+2 bleed + restores morale equal to damage. Adds Physical damage modifier."
	damage_type = damage_types.physical
	target=action_target.enemies_individual

func execute(user: Unit, target:Unit):
	if !target: return
	
	var d = Dice.opposed_roll(12, 
	user.agility+user.dominance-user.status_manager.exhaustion-user.status_manager.suppression, 
	target.agility-target.status_manager.exhaustion-target.status_manager.exhaustion
	)
	var damage = 0
	var bleed = 0
	var bleed_mult=1
	
	print("[attack] ", str(user.unit_name), " twists the blade on ", str(target.unit_name))
	
	if d == Dice.roll_result.success:
		damage = user.strength + power
		bleed_mult=2
		bleed = user.agility/2
		print("   attack deals ", str(damage), " damage")
	elif d == Dice.roll_result.partial_success:
		bleed_mult=2
		damage = int(user.strength + power * 0.5)
		print("   attack deals ", str(damage), " damage")
	elif d == Dice.roll_result.partial_fail:
		damage = int(user.strength + power * 0.25)
		print("   attack deals ", str(damage), " damage")
	elif d == Dice.roll_result.fail:
		print("   attack miss")
		return
	elif d == Dice.roll_result.crit:
		damage = int(user.strength + power * 2)
		bleed_mult=3
		bleed = 2+user.agility/2
		user.receive_morale_damage(-damage)
		print("   attack deals ", str(damage), " damage")
		print("   gained ", str(damage), " morale")
	
	target.status_manager.add_bleed(bleed+user.get_phys_damage_mod())
	target.status_manager.bleed*=bleed_mult
	target.receive_damage(damage)
