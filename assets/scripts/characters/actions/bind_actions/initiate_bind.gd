class_name ActionInitiateBind
extends Action

@export var threshold := 12

func _init() -> void:
	action_name = "Initiate Bind"
	description="Grab an enemy and enter a bind. Higher of STR/AGI vs. higher of target's STR/AGI/Body. Success sets your dominance to STR, theirs to 0. Partial success splits dominance. Partial fail enters bind with both at 0 dominance. Crit also stuns target, shifts morale, and sets your dominance to full STR. Fail stuns you instead. Cannot bind an already-bound unit."
	target=action_target.enemies_individual

func execute(user: Unit, target:Unit) -> void:
	if user.bind_target != null: return
	
	if target == null or target.bind_target != null: return

	var result := Dice.opposed_roll(
		threshold,
		max(user.strength, user.agility),
		max(target.strength, target.agility, target.body)
	)
	
	print("[action] ", user.unit_name, " initiates bind")
	
	match result:
		Dice.roll_result.crit:
			print("   CRIT!!!")
			user.enter_bind(target)
			user.dominance = user.strength
			target.dominance = 0
			target.status_manager.stun+=1
			user.receive_morale_damage(-1)
			target.receive_morale_damage(2)
		
		Dice.roll_result.success:
			print("   success")
			user.enter_bind(target)
			user.dominance = user.strength
			target.dominance = 0

		Dice.roll_result.partial_success:
			print("   partial success")
			user.enter_bind(target)
			user.dominance = int(user.strength * 0.5)
			target.dominance = int(target.strength * 0.25)

		Dice.roll_result.partial_fail:
			print("   partial fail")
			user.enter_bind(target)
			user.dominance = 0
			target.dominance = 0

		Dice.roll_result.fail:
			print("   fail")
			user.status_manager.stun+=1

func _pick_target(enemies: Array) -> Unit:
	for e in enemies:
		if e.alive:
			return e
	return null
