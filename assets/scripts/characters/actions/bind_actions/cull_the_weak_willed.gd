class_name CullWeakWillBind
extends Action

@export var threshold := 15

func _init() -> void:
	action_name = "Cull The Weak-Willed"
	description = "Unleash a finishing blow on a bound enemy. Deals 1 + 2–8× missing morale damage, escaping the bind on hit. Crit deals 1 + 15× missing morale and also escapes. Partial fail deals damage but doesn't escape. Fail gives opponent +STR dominance instead. AGI + max(Mind, STR) vs. opponent dominance + max(STR, AGI, Body). Adds Magic modifier."
	damage_type = damage_types.magic

func execute(user: Unit, target:Unit) -> void:
	if user.bind_target == null:
		return

	var opponent := user.bind_target

	var result := Dice.opposed_roll(
		threshold,
		user.agility + max(user.mind, user.strength) - user.status_manager.exhaustion,
		opponent.dominance + max(opponent.strength, opponent.agility, opponent.body) - opponent.status_manager.exhaustion
	)
	
	var damage
	var opp = opponent
	
	print("[action] ", user.unit_name, " culls the weak-willed")
	match result:
		Dice.roll_result.crit:
			print("   CRIT!!!")
			user.escape_bind()
			damage = 1+15*(target.max_morale-target.current_morale)
		
		Dice.roll_result.success:
			print("   success")
			damage = 1+8*(target.max_morale-target.current_morale)
			user.escape_bind()

		Dice.roll_result.partial_success:
			print("   partial success")
			user.escape_bind()
			damage = 1+4*(target.max_morale-target.current_morale)

		Dice.roll_result.partial_fail:
			print("   partial fail")
			damage = 1+2*(target.max_morale-target.current_morale)

		Dice.roll_result.fail:
			print("   fail")
			opponent.dominance += opponent.strength
	opp.receive_damage(damage+user.get_magic_damage_mod())
	
