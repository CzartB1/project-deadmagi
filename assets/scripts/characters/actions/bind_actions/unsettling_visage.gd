class_name UnsettlingVisageAction # BIND ONLY ACTION
extends Action

@export var threshold := 15

func _init() -> void:
	action_name = "Unsettling Visage"
	damage_type = damage_types.magic

func execute(user: Unit, target:Unit) -> void: # TARGET ONLY USED CUZ BASE EXECUTE FUNC NEEDS IT
	if user.bind_target == null:
		return

	var opponent := user.bind_target # USE THIS TO REFER TO THE TARGET

	var result := Dice.opposed_roll(
		threshold,
		max(user.mind,user.will),
		1+opponent.will*(opponent.max_morale-opponent.current_morale)
	)

	print("[action] ",user.unit_name," unsettles their enemy.")
	match result:
		Dice.roll_result.crit:
			print("   CRIT!!!")
			user.dominance += user.strength
			opponent.dominance = opponent.dominance - (user.strength+user.get_magic_damage_mod())
			opponent.status_manager.stun+=1
			opponent.receive_damage(1+user.get_magic_damage_mod(),false)
			user.receive_morale_damage(-1+user.get_magic_damage_mod())
			opponent.receive_morale_damage(1+user.get_magic_damage_mod())
		
		Dice.roll_result.success:
			print("   success")
			user.dominance += user.strength
			opponent.dominance = opponent.dominance - (user.strength+user.get_magic_damage_mod())
			opponent.receive_damage(1+user.get_magic_damage_mod(),false)
			user.receive_morale_damage(-1+user.get_magic_damage_mod())
			opponent.receive_morale_damage(1+user.get_magic_damage_mod())

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
