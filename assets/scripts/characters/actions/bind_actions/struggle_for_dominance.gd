class_name ActionStruggleBind
extends Action

@export var threshold := 15

func _init() -> void:
	action_name = "Struggle"
	description = "Fight for control within a bind. max(STR, AGI) vs. opponent's max(STR, Body). Hit gains you STR dominance, reduces theirs by STR, and deals 1+STR damage. Partial success gains STR×0.5 dominance. Partial fail gives opponent STR×0.5 dominance. Fail gives opponent full STR dominance + 1 exhaustion + 1 morale damage to you. Crit also stuns opponent and exchanges 1 morale."

func execute(user: Unit, target:Unit) -> void:
	if user.bind_target == null:
		return

	var opponent := user.bind_target

	var result := Dice.opposed_roll(
		threshold,
		max(user.strength,user.agility),
		max(opponent.strength,opponent.body)
	)

	print("[action] ",user.unit_name," struggles for dominance")
	match result:
		Dice.roll_result.crit:
			print("   CRIT!!!")
			user.dominance += user.strength
			opponent.dominance = opponent.dominance - user.strength
			opponent.status_manager.stun+=1
			opponent.receive_damage(1+(user.strength),false)
			user.receive_morale_damage(-1)
			opponent.receive_morale_damage(1)
		
		Dice.roll_result.success:
			print("   success")
			user.dominance += user.strength
			opponent.dominance = opponent.dominance - user.strength
			opponent.receive_damage(1+(user.strength),false)
			user.receive_morale_damage(-1)
			opponent.receive_morale_damage(1)

		Dice.roll_result.partial_success:
			print("   partial success")
			user.dominance += int(user.strength * 0.5)

		Dice.roll_result.partial_fail:
			print("   partial fail")
			opponent.dominance += int(opponent.strength * 0.5)

		Dice.roll_result.fail:
			print("   fail")
			opponent.dominance += opponent.strength
			user.status_manager.exhaustion+=1
			user.receive_morale_damage(1)
	user.binded_update.emit()
	opponent.binded_update.emit()
	print("   ", user.unit_name,"'s dominance: ", str(user.dominance))
	print("   ", opponent.unit_name,"'s dominance: ", str(opponent.dominance))
