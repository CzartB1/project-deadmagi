class_name StatusManager
extends Node

@export var unit: Unit

var bleed: int = 0        # DoT — deals stack as damage, then decays by 1
var poison: int = 0       # DoT — deals stack as damage, then decays by 1
var burn: int = 0         # DoT — deals stack as damage, then decays by 1
var regen: int = 0        # HoT — heals stack as HP, then decays by 1
var terror: int = 0       # morale damage multiplier — +1 per stack (x1, x2, x3...)
var stun: int = 0         # skip turn
var suppression: int = 0  # reduce accuracy
var exhaustion: int = 0   # general roll reduction
var rage: int = 0         # phys damage bonus
var frailty: int = 0      # unit takes more damage
var weakened: int = 0     # unit phys and tech damage reduction
var momentum: int = 0     # phys damage bonus
var disrupted: int = 0    # magic damage reduction
var focus: int = 0        # magic and tech damage bonus
var barrier: int = 0      # cancels one attack per stack; decays if not triggered

var momentum_changed: bool = false
signal status_update


# =========================
# TURN UPDATE HOOKS
# =========================

func update_status(): # pre-turn
	update_bleed()
	update_poison()
	update_burn()
	update_regen()
	update_terror()

	momentum_changed = false

	status_update.emit()

func late_update_status(): # post-turn
	update_suppression()
	update_exhaustion()
	update_stun()
	update_rage()
	update_frailty()
	update_weakened()
	update_disrupted()
	update_focus()
	update_barrier()

	if momentum_changed:
		momentum = 0

	status_update.emit()


# =========================
# QUERIES
# =========================

func has_any() -> bool:
	return (bleed > 0 or poison > 0 or burn > 0 or regen > 0 or terror > 0 or stun > 0
		or suppression > 0 or exhaustion > 0 or rage > 0
		or frailty > 0 or weakened > 0 or momentum > 0
		or disrupted > 0 or focus > 0 or barrier > 0)

func stunned() -> bool:
	return stun > 0

## Returns the morale damage multiplier from terror.
## 0 stacks = x1, 1 stack = x2, 2 stacks = x3, etc.
func get_terror_multiplier() -> int:
	return 1 + terror

## Returns true and consumes one barrier stack if barrier is active.
## Call this in receive_damage() before applying damage.
func try_barrier() -> bool:
	if barrier <= 0: return false
	barrier -= 1
	status_update.emit()
	return true

func get_status_string() -> String: # TODO: replace with icons
	var s := ""
	if barrier > 0:    s += "[bar " + str(barrier) + "]"
	if bleed > 0:      s += "[bld " + str(bleed) + "]"
	if poison > 0:     s += "[psn " + str(poison) + "]"
	if burn > 0:       s += "[brn " + str(burn) + "]"
	if regen > 0:      s += "[rgn " + str(regen) + "]"
	if terror > 0:     s += "[trr " + str(terror) + "]"
	if stun > 0:       s += "[stn " + str(stun) + "]"
	if suppression > 0:s += "[spr " + str(suppression) + "]"
	if exhaustion > 0: s += "[exh " + str(exhaustion) + "]"
	if rage > 0:       s += "[rge " + str(rage) + "]"
	if frailty > 0:    s += "[frl " + str(frailty) + "]"
	if weakened > 0:   s += "[wkn " + str(weakened) + "]"
	if momentum > 0:   s += "[mnt " + str(momentum) + "]"
	if disrupted > 0:  s += "[dsr " + str(disrupted) + "]"
	if focus > 0:      s += "[foc " + str(focus) + "]"
	return s


# =========================
# BLEED
# =========================

func update_bleed():
	if bleed <= 0: return
	unit.receive_damage(bleed)
	bleed -= 1

func add_bleed(amount: int):
	bleed += amount
	status_update.emit()


# =========================
# POISON
# =========================

func update_poison():
	if poison <= 0: return
	unit.receive_damage(poison)
	poison -= 1

func add_poison(amount: int):
	poison += amount
	status_update.emit()


# =========================
# BURN
# =========================

func update_burn():
	if burn <= 0: return
	unit.receive_damage(burn)
	burn -= 1

func add_burn(amount: int):
	burn += amount
	status_update.emit()


# =========================
# REGEN
# =========================

func update_regen():
	if regen <= 0: return
	unit.receive_damage(-regen)
	regen -= 1

func add_regen(amount: int):
	regen += amount
	status_update.emit()


# =========================
# BARRIER
# =========================

## Decays passively at end of turn if it wasn't triggered by an attack.
func update_barrier():
	if barrier <= 0: return
	barrier -= 1

func add_barrier(amount: int):
	barrier += amount
	status_update.emit()


# =========================
# TERROR
# =========================

## Terror decays each pre-turn tick.
## Its effect is applied externally via get_terror_multiplier()
## when morale damage is dealt to this unit.
func update_terror():
	if terror <= 0: return
	terror -= 1

func add_terror(amount: int):
	terror += amount
	status_update.emit()


# =========================
# STUN
# =========================

func update_stun():
	if stun <= 0: return
	stun -= 1

func add_stun(amount: int):
	stun += amount
	status_update.emit()


# =========================
# SUPPRESSION
# =========================

func update_suppression():
	if suppression <= 0: return
	suppression -= 1

func add_suppression(amount: int):
	suppression += amount
	status_update.emit()


# =========================
# EXHAUSTION
# =========================

func update_exhaustion():
	if exhaustion <= 0: return
	exhaustion -= 1

func add_exhaustion(amount: int):
	exhaustion += amount
	status_update.emit()


# =========================
# RAGE
# =========================

func update_rage():
	if rage <= 0: return
	rage -= 1

func add_rage(amount: int):
	rage += amount
	status_update.emit()


# =========================
# FRAILTY
# =========================

func update_frailty():
	if frailty <= 0: return
	frailty -= 1

func add_frailty(amount: int):
	frailty += amount
	status_update.emit()


# =========================
# WEAKENED
# =========================

func update_weakened():
	if weakened <= 0: return
	weakened -= 1

func add_weakened(amount: int):
	weakened += amount
	status_update.emit()


# =========================
# MOMENTUM
# =========================

func add_momentum(amount: int):
	momentum += amount
	momentum_changed = true
	status_update.emit()


# =========================
# DISRUPTED
# =========================

func update_disrupted():
	if disrupted <= 0: return
	disrupted -= 1

func add_disrupted(amount: int):
	disrupted += amount
	status_update.emit()


# =========================
# FOCUS
# =========================

func update_focus():
	if focus <= 0: return
	focus -= 1

func add_focus(amount: int):
	focus += amount
	status_update.emit()
