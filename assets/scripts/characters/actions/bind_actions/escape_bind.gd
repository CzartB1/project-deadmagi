class_name ActionEscapeBind
extends Action

@export var threshold := 15

func _init() -> void:
	action_name = "Escape Bind"

func execute(user: Unit, target:Unit) -> void:
	if user.bind_target == null:
		return

	var opponent := user.bind_target

	var result := Dice.opposed_roll(
		threshold,
		user.agility + max(user.mind, user.strength) - user.status_manager.exhaustion,
		opponent.dominance + max(opponent.strength, opponent.agility, opponent.body) - opponent.status_manager.exhaustion
	)
	
	print("[action] ", user.unit_name, " attempts to escape bind")
	match result:
		Dice.roll_result.crit:
			print("   CRIT!!!")
			user.escape_bind()
			user.receive_morale_damage(-2)
			opponent.receive_morale_damage(2)
			opponent.status_manager.stun+=1
		
		Dice.roll_result.success:
			print("   success")
			user.receive_morale_damage(-2)
			user.escape_bind()

		Dice.roll_result.partial_success:
			print("   partial success")
			user.escape_bind()
			user.status_manager.exhaustion+=2
			user.receive_morale_damage(1)

		Dice.roll_result.partial_fail:
			print("   partial fail")
			user.status_manager.exhaustion+=2
			user.receive_morale_damage(1)

		Dice.roll_result.fail:
			print("   fail")
			user.status_manager.exhaustion+=2
			user.receive_morale_damage(2)
			opponent.dominance += opponent.strength
