extends Node

signal crit

var notif:NotificationManager

enum roll_result{
	success,
	partial_success,
	partial_fail,
	fail,
	crit
}

func opposed_roll(threshold:int=10, action_bonus:int=0, challenge_bonus:int=0, dice_size:int=20) -> roll_result:
	if !notif: notif=get_tree().get_first_node_in_group("Notification")
	var a_roll = randi_range(1,dice_size)+action_bonus
	var c_roll = randi_range(1,dice_size)+challenge_bonus
	print("[dice] a_roll : ", str(a_roll-action_bonus)," + ",str(action_bonus)," = ",str(a_roll), "\n", 
	"   c_roll : ", str(c_roll-challenge_bonus)," + ",str(challenge_bonus)," = ",str(c_roll), "\n",
	"   treshhold : ", str(threshold)
	)
	if a_roll<threshold and c_roll<threshold: 
		if a_roll==c_roll: 
			print("   result : CRIT!!!")
			notif.notify("CRITICAL",notif.Tag.NONE,true)
			crit.emit()
			return roll_result.crit
		print("   result : partial fail")
		return roll_result.partial_fail
	elif a_roll>=threshold and c_roll>=threshold: 
		print("   result : partial success")
		return roll_result.partial_success
	elif a_roll>=threshold and c_roll<threshold: 
		print("   result : success")
		return roll_result.success
	else:
		print("   result : fail")
		notif.notify("FAIL",notif.Tag.NONE,true)
		return roll_result.fail
