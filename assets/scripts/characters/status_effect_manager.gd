class_name StatusManager
extends Node

@export var unit:Unit
@export var poison_damage:int=4

var bleed:int = 0 # DoT
var poison:int = 0 # DoT
var terror:int = 0 # morale damage received multiplier
var stun:int = 0 # skip turn
var suppression:int = 0 # reduce accuracy
var exhaustion:int = 0 # general roll reduction
var rage:int=0 # phys damage bonus
var frailty:int=0 # unit takes more damage
var weakened:int=0 # unit phys and tech damage reduction
var momentum:int=0 # phys damage bonus
var disrupted:int=0 # magic damage reduction
var focus:int=0 #magic and tech damage bonus
var burn:int=0 #TODO DoT

var momentum_changed:bool=false
signal status_update

func update_status(): #updated pre-turn
	update_bleed()
	update_poison()
	update_terror()
	
	momentum_changed=false
	
	status_update.emit()

func late_update_status(): # updated post-turn
	update_suppression()
	update_exhaustion()
	update_stun()
	
	if momentum_changed:momentum=0
	
	status_update.emit()

func has_any() -> bool:
	return rage>0 or bleed>0 or poison>0 or terror>0 or stun>0 or suppression>0 or exhaustion>0

func get_status_string()->String: #TODO replace with icons
	var s := ""
	if bleed>0:s=s+"[bld "+str(bleed)+"]"
	if rage>0:s=s+"[rge "+str(rage)+"]"
	if poison>0:s=s+"[psn "+str(poison)+"]"
	if terror>0:s=s+"[trr "+str(terror)+"]"
	if stun>0:s=s+"[stn "+str(stun)+"]"
	if suppression>0:s=s+"[spr "+str(suppression)+"]"
	if exhaustion>0:s=s+"[exh "+str(exhaustion)+"]"
	if frailty>0:s=s+"[frl "+str(frailty)+"]"
	if momentum>0:s=s+"[mnt "+str(momentum)+"]"
	if disrupted>0:s=s+"[dsr "+str(disrupted)+"]"
	if focus>0:s=s+"[foc "+str(focus)+"]"
	if weakened>0:s=s+"[wkn "+str(weakened)+"]"
	return s

func update_bleed():
	if bleed<=0: return
	unit.receive_damage(bleed)
	bleed-=1

func add_bleed(amount:int):
	bleed+=amount
	status_update.emit()

func add_poison(amount:int):
	poison+=amount
	status_update.emit()

func update_poison():
	if poison<=0: return
	unit.receive_damage(poison_damage)
	poison-=1

func update_terror():
	if terror<=0: return
	#TODO morale damage
	if unit.bind_target: unit.dominance = max(0, unit.dominance - terror)
	terror-=1

func update_stun():
	if stun<=0: return
	stun-=1

func add_stun(amount:int):
	stun+=amount
	status_update.emit()

func stunned() -> bool:
	return stun > 0

func update_suppression():
	if suppression<=0: return
	suppression-=1

func add_suppression(amount:int):
	suppression+=amount
	status_update.emit()

func update_exhaustion():
	if exhaustion<=0: return
	#TO DO debuff rolls
	exhaustion-=1

func add_exhaustion(amount:int):
	exhaustion+=amount
	status_update.emit()

func update_rage():
	if rage<=0: return
	rage-=1

func add_rage(amount:int):
	rage+=amount
	status_update.emit()

func add_momentum(amount:int):
	momentum+=amount
	momentum_changed=true
	status_update.emit()

func update_frailty():
	if frailty<=0: return
	frailty-=1

func add_frailty(amount:int):
	frailty+=amount
	status_update.emit()

func update_disrupted():
	if disrupted<=0: return
	disrupted-=1

func add_disrupted(amount:int):
	disrupted+=amount
	status_update.emit()

func update_focus():
	if focus<=0: return
	focus-=1

func add_focus(amount:int):
	focus+=amount
	status_update.emit()

func update_weakened():
	if weakened<=0: return
	weakened-=1

func add_weakened(amount:int):
	weakened+=amount
	status_update.emit()
