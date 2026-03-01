class_name Unit
extends Node

enum morale_state{
	calm,
	shaken,
	panicking
}

enum roles{
	assassin,
	ravager,
	depleter,
	tank,
	buffer,
	debuffer,
	healer,
	controller,
	wildcard
}

enum Stat {
	strength,
	agility,
	body,
	mind,
	will
}

@export var unit_name: String
@export var is_ally: bool = true
@export var primary_role:roles
@export var secondary_role:roles
@export var status_manager:StatusManager
@export var turn_cam:PhantomCamera3D
@export var bind_cam:PhantomCamera3D
@export var action_panel:UnitActionPanel
var god_mode=false
var panel:UnitPanel
var protector:Unit
var protector_timer:int
var protected_units:Array[Unit]

@export_group("lore")
@export var backstory: String = ""
@export var portrait: Texture2D = null

@export_group("stats")
@export var base_strength: int = 5
@export var base_agility: int = 5
@export var base_body: int = 5
@export var base_mind: int = 5
@export var base_will: int = 5
var strength: int = 5
var agility: int = 5
var body: int = 5
var mind: int = 5
var will: int = 5

var phys_mod:int=0
var magic_mod:int=0
var tech_mod:int=0

@export_subgroup("Base HP and Morale")
@export var base_hp: int = 20
@export var base_morale: int = 20

@export_subgroup("Level_up")
## Flat XP required for level 1. Each subsequent level costs base * level.
## e.g. base 100 → lvl1=100, lvl2=200, lvl3=300 …
@export var xp_base: int = 100

## Pattern of stat gains applied every 5 levels, in order.
## Loops back to index 0 when exhausted.
@export var stat_growth_pattern: Array[StatGain] = []

@export_group("actions")
@export var actions: Array[Action]
@export var default_action_index: int = 0
var forced_target:Unit
@export_group("bind")
@export var binded_actions: Array[Action]
var bind_target: Unit = null
var dominance: int = 0
@export_group("visual")
@export var model: UnitModel3D

var selected_action_index: int = 0
var alive: bool = true
var max_hp:int
var current_hp:int
var max_morale:int
var current_morale:int
var current_morale_state:morale_state=morale_state.calm
var previous_line: FormationLine3D
var bind_line: FormationLine3D
var previous_index: int
var current_turn=false
var battle_manager:BattleManager
var current_level: int = 1
var current_xp: int = 0
var xp_to_next_level: int = 100   # recalculated after each level-up
var has_acted: bool = false        # reset at battle start; used for XP split
var _stat_growth_index: int = 0   # tracks position in stat_growth_pattern
var notif:NotificationManager

signal update_action
signal binded_update
signal name_ready
signal attacked
signal damaged
signal morale_damaged
signal died
signal protection_update
signal setup_enemy_ui
signal levelled_up(new_level: int)
signal xp_gained(amount: int)	

# =========================
# ITEM SYSTEM PREP
# =========================
@export_group("items")
#var item_slots: Array[Item] = []
var max_item_slots := 4
var action_manager: ActionManager
var equipped_items: Array[Item] = []

func _ready():
	if unit_name.is_empty(): 
		var g=randi_range(0,2)
		if g==0:unit_name=NameGen.get_female_name()
		elif g==1:unit_name=NameGen.get_male_name()
		else:unit_name=NameGen.get_nickname()
		name_ready.emit()
	selected_action_index = default_action_index
	max_hp=base_hp+body
	max_morale=base_morale+will
	current_hp=max_hp
	current_morale=max_morale
	GameManager.battle_composition_changed.connect(check_bind_status)
	current_turn=false
	equipped_items.resize(max_item_slots)
	action_manager = ActionManager.new()
	add_child(action_manager)
	action_manager.setup(self)
	setup_enemy_ui.emit()
	xp_to_next_level = _calc_xp_threshold(current_level)
	if !notif: notif=get_tree().get_first_node_in_group("Notification")

func get_action() -> Action: 
	return actions[selected_action_index]

func get_binded_action() -> Action:
	return action_manager.total_bind_actions[min(
		selected_action_index,
		action_manager.total_bind_actions.size() - 1
	)]

func check_bind_status(): # in case bind target dies and unit forgor to update
	if !bind_target:
		update_action.emit()
		binded_update.emit()

func take_turn(allies: Array, enemies: Array):
	if current_hp <= 0 and GameManager.current_state==GameManager.game_state.battle:
		return
	if bind_target and !bind_target.alive: escape_bind()
	
	if status_manager.has_any(): status_manager.update_status()
	if status_manager.stunned(): 
		status_manager.late_update_status()
		return
	
	if !is_ally:
		ai_decisionmaking()
		forced_target=null
		if current_morale_state == morale_state.panicking:
			if try_flee(): 
				return
	current_turn=true
	
	var target:Unit
	# if binded can only attack bind target
	if forced_target and forced_target.alive: target=forced_target 
	else:
		var u = get_tree().get_nodes_in_group("Unit")
		u = u.filter(func(unit:Unit): return unit.is_ally != is_ally and unit.alive)
		target=u.pick_random()
	
	if bind_target: # when binded
		print("[unit] ", unit_name," binded with ", bind_target.unit_name)
		print("   dominance: ", str(dominance), " | ",bind_target.unit_name,"'s dominance: ", str(bind_target.dominance))
		if dominance<bind_target.dominance: 
			var gap = bind_target.dominance - dominance
			var dmg = max(1, gap)
			receive_damage(dmg,false)
		else:
			# everytime on top, roll to check if get exhaustion. prevents infinite bind
			var e_roll=Dice.opposed_roll(10, min(body,strength), status_manager.exhaustion+bind_target.strength)
			if e_roll==Dice.roll_result.fail: 
				status_manager.exhaustion = min(status_manager.exhaustion + 2, 10)
				receive_morale_damage(1)
			elif e_roll==Dice.roll_result.partial_fail: status_manager.exhaustion = min(status_manager.exhaustion + 1, 10)
			elif e_roll==Dice.roll_result.success: bind_target.status_manager.exhaustion = min(bind_target.status_manager.exhaustion + 1, 10) # reversal hehehehe
			elif e_roll==Dice.roll_result.crit: bind_target.status_manager.exhaustion = min(bind_target.status_manager.exhaustion + 2, 10) # super reversal hehehehe
		#dominance+=strength
		emit_signal("attacked")
		binded_update.emit()
		#bind_target.binded_update.emit()
		get_binded_action().execute(self, bind_target)
	else: # when not binded
		emit_signal("attacked")
		get_action().execute(self, target)
	if status_manager.has_any(): status_manager.late_update_status()
	has_acted = true

func receive_damage(amount:int, dominance_loss:bool=true, redirected:bool=false):
	#Redirected is basically to tell the receiver to not redirect it again.
	if !alive or god_mode or status_manager.try_barrier(): return
	if protector and !bind_target and !redirected:
		protector.receive_damage(amount, dominance_loss, true)
		protector_timer -= 1
		if protector_timer <= 0:
			protector.protected_units.erase(self)
			protector = null
			protection_update.emit()
		return
	current_hp -= (amount+status_manager.frailty)
	emit_signal("damaged")

	if bind_target:
		binded_update.emit()
		if dominance_loss:
			dominance -= bind_target.strength
			if dominance < 0:
				dominance = 0

	if current_hp > 0:
		return
	alive = false
	if bind_target:
		escape_bind()
	on_unit_died_morale_damage(self)
	if protected_units.size() > 0:
		for p in protected_units.duplicate():
			p.protector_timer = 0
			p.protector = null
			p.protection_update.emit()
		protected_units.clear()

	if protector:
		protector.protected_units.erase(self)
		protector_timer = 0
		protector = null
		protection_update.emit()

	if model and model.current_line:
		model.current_line.remove_unit(self)
		model.queue_free()

	emit_signal("died")
	GameManager.battle_composition_changed.emit()
	queue_free()

func receive_morale_damage(amount: int):
	var mult:int=status_manager.get_terror_multiplier()
	if god_mode: return
	if current_hp<(max_hp*0.5): mult+=1
	if current_morale_state==morale_state.shaken: mult+=1
	if current_morale_state==morale_state.panicking: mult+=2
	current_morale = clamp(current_morale - (amount * mult), 0, max_morale)
	morale_check()
	morale_damaged.emit()

func restore_morale(amount: int):
	current_morale = clamp(current_morale + amount, 0, max_morale)
	morale_check()
	morale_damaged.emit()

func morale_check():
	if current_morale>=(max_morale*0.4): current_morale_state=morale_state.calm
	elif current_morale>=(max_morale*0.1): current_morale_state=morale_state.shaken
	elif current_morale<(max_morale*0.1) and current_morale>0: current_morale_state=morale_state.panicking
	else: breakdown()

func breakdown():
	print("[morale] ", unit_name, " suffers a breakdown!")

	var roll := randi_range(1, 100)

	# Heavily wounded units are more likely to die
	if current_hp < max_hp * 0.25:
		roll -= 25

	if roll <= 25:
		# Heart attack / shock
		print("  > fatal breakdown")
		receive_damage(current_hp + 1)
		return

	elif roll <= 60:
		# Total collapse
		print("  > incapacitated")
		status_manager.stun += 2
		status_manager.exhaustion = min(status_manager.exhaustion + 3, 10)
		current_morale = int(max_morale * 0.2)
		current_morale_state = morale_state.shaken

	else:
		# Panic surge, but survives
		print("  > panicked recovery")
		status_manager.stun += 1
		current_morale = int(max_morale * 0.3)
		current_morale_state = morale_state.panicking

	morale_damaged.emit()

func enter_bind(target: Unit):
	if bind_target or not target:
		return
	
	if protected_units.size()>0:
		for u in protected_units: u.protector=null
		protected_units.clear()
	if protector: protector=null
	
	# Store original positions FIRST
	previous_line = model.current_line
	previous_index = previous_line.units.find(self)

	target.previous_line = target.model.current_line
	target.previous_index = target.previous_line.units.find(target)

	# Remove from original lines
	previous_line.remove_unit(self)
	target.previous_line.remove_unit(target)

	# Set bind state ONCE
	bind_target = target
	target.bind_target = self

	dominance = strength
	target.dominance = 0

	# Add both to bind line
	bind_line.add_unit(self)
	bind_line.add_unit(target)

	update_action.emit()
	target.update_action.emit()
	binded_update.emit()
	target.binded_update.emit()

func escape_bind():
	if not bind_target:
		return

	var other := bind_target

	# Remove from bind line
	bind_line.remove_unit(self)
	bind_line.remove_unit(other)

	# Restore to original lines
	if previous_line:
		previous_line.add_unit(self, previous_index)

	if other.previous_line:
		other.previous_line.add_unit(other, other.previous_index)

	model.mesh.global_position=model.global_position #FIXME idk why but mesh position kinda fucks up when leaving bind
	
	# Clear bind state
	bind_target = null
	other.bind_target = null

	dominance = 0
	other.dominance = 0

	update_action.emit()
	other.update_action.emit()
	binded_update.emit()
	other.binded_update.emit()
	model.reset_model_pos()
	other.model.reset_model_pos()

func ai_decisionmaking():
	var roll := randi_range(0, 100)
	
	if current_morale_state == morale_state.panicking: # Panicking units act irrationally
		# 40% chance to do nothing useful (freeze / hesitate)
		if roll <= 40:
			selected_action_index = 0
			return
		# 30% chance to try escaping even if it's bad
		if bind_target and roll <= 70:
			selected_action_index = 1
			return
		# Otherwise behave poorly (random choice)
		selected_action_index = randi_range(0, actions.size() - 1)
		return

	# --- SHAKEN (less reliable but still functional) ---
	if current_morale_state == morale_state.shaken:
		roll -= 20 # worse judgment
	# --- NORMAL LOGIC ---
	if bind_target:
		# Escaping becomes more likely only if exhausted AND dominated
		if status_manager.exhaustion > 5 and dominance < bind_target.dominance:
			if roll <= 50:
				selected_action_index = 1 # escape
			else:
				selected_action_index = 0 # struggle
		else:
			selected_action_index = 0
	else:
		# Initiate bind rarely and mostly by suitable units
		if roll <= 15:
			selected_action_index = 1
		else:
			selected_action_index = 0

func on_unit_died_morale_damage(dead_unit: Unit):
	var units = get_tree().get_nodes_in_group("Unit")
	for u in units:
		if not u.alive or u == dead_unit:
			continue
		
		if u.is_ally == dead_unit.is_ally:
			u.receive_morale_damage(8)
		else:
			u.receive_morale_damage(-5)

func try_flee() -> bool:
	var chance := get_flee_chance()
	if randf() <= chance:
		flee()
		return true
	return false

func flee():
	print("[morale] ", unit_name, " panics and flees!")
	alive = false
	on_unit_died_morale_damage(self)
	emit_signal("died")
	GameManager.battle_composition_changed.emit()
	queue_free()

func get_flee_chance() -> float:
	if current_morale_state != morale_state.panicking:
		return 0.0

	var ratio := float(current_morale) / max_morale
	return clamp(1.0 - (ratio * 5.0), 0.1, 1.0)

func add_protector(unit: Unit, prot_time:int=3):
	if unit == self:
		push_error("Unit cannot protect itself")
		return

	if protector != null and protector != unit:
		protector.protected_units.erase(self)

	if protected_units.has(unit):
		print("[unit] ", unit.unit_name, " attempted mutual protection. Breaking loop.")
		protected_units.erase(unit)
		unit.protector = null
		unit.protected_units.erase(self)

	protector = unit
	if not unit.protected_units.has(self):
		unit.protected_units.append(self)
	protector_timer=prot_time
	protection_update.emit()

func get_used_item_slots() -> int:
	var used := 0
	for item in equipped_items:
		used += item.slot_cost
	return used

func equip_item(slot: int, item: Item):
	if slot < 0 or slot >= max_item_slots: return
	if equipped_items.size()>0:
		if equipped_items[slot] != null: unequip_item(slot)

		equipped_items[slot] = item
		item.on_equip(self)
		stat_rebuild()
		action_manager.rebuild_from_items()

func unequip_item(slot: int):
	var item=equipped_items[slot]
	item.on_unequip(self)
	equipped_items.remove_at(slot)
	stat_rebuild()
	action_manager.rebuild_from_items()

func stat_rebuild():
	strength = base_strength
	mind = base_mind
	agility = base_agility
	body = base_body
	will = base_will

	for item in equipped_items:
		if item == null: continue
		strength += item.strength_bonus
		mind += item.mind_bonus
		agility += item.agility_bonus
		body += item.body_bonus
		will += item.will_bonus

func get_tech_damage_mod()->int:
	var fr=0
	if status_manager.weakened: fr=3 
	else: fr=0
	return max(mind - 5, 0) + status_manager.focus + tech_mod - fr

func get_phys_damage_mod()->int:
	var fr=0
	var ex=0
	if status_manager.weakened: fr=8 
	else: fr=0
	if status_manager.exhaustion: ex=3 
	else: ex=0
	return max(strength + agility - 10, 0) + status_manager.rage + status_manager.momentum + phys_mod - fr - ex

func get_magic_damage_mod()->int:
	var bl=0
	var ex=0
	if status_manager.disrupted: bl=6 
	else: bl=0
	if status_manager.frailty: ex=6 
	else: ex=0
	return max(mind + will - 10, 0) + status_manager.focus + magic_mod - bl - ex

func cam_setup():
	if model.global_position.x<model.current_line.global_position.x:
		turn_cam.position.x = -model.global_position.distance_to(model.current_line.global_position)*0.35
	else: turn_cam.position.x = model.global_position.distance_to(model.current_line.global_position)*0.35

## Called by BattleManager at the start of each battle.
func on_battle_start():
	has_acted = false

## Award XP. amount should already be pre-scaled (full or 50%) by the caller.
func gain_xp(amount: int):
	if not is_ally:
		return
	current_xp += amount
	xp_gained.emit(amount)
	notif.notify(unit_name+" gained xp: "+str(amount)+"/"+str(xp_to_next_level),notif.Tag.XP)
	while current_xp >= xp_to_next_level:
		current_xp -= xp_to_next_level
		_level_up()

func _level_up():
	current_level += 1
	xp_to_next_level = _calc_xp_threshold(current_level)

	# Every level: +1 to all damage modifier types
	phys_mod  += 1
	magic_mod += 1
	tech_mod  += 1

	# Every 5 levels: apply next entry from the stat growth pattern
	if current_level % 5 == 0:
		_apply_stat_growth()

	levelled_up.emit(current_level)
	print("[levelup] %s reached level %d | phys_mod=%d magic_mod=%d tech_mod=%d"
		% [unit_name, current_level, phys_mod, magic_mod, tech_mod])
	notif.notify(unit_name+" levelled up to level: "+str(current_level),notif.Tag.XP, true)

func _apply_stat_growth():
	if stat_growth_pattern.is_empty():
		return

	var gain: StatGain = stat_growth_pattern[_stat_growth_index % stat_growth_pattern.size()]
	_stat_growth_index += 1

	match gain.stat:
		StatGain.Stat.strength:
			base_strength += gain.amount
		StatGain.Stat.agility:
			base_agility  += gain.amount
		StatGain.Stat.body:
			base_body     += gain.amount
		StatGain.Stat.mind:
			base_mind     += gain.amount
		StatGain.Stat.will:
			base_will     += gain.amount

	# Rebuild derived stats so HP/morale caps and damage mods update immediately
	stat_rebuild()
	# Optionally restore HP/morale proportionally so a level-up doesn't heal
	# mid-battle. Remove the two lines below if you want it to heal instead.
	max_hp     = base_hp     + body
	max_morale = base_morale + will

	print("[levelup] %s stat milestone: %s +%d (now at level %d)"
		% [unit_name, StatGain.Stat.keys()[gain.stat], gain.amount, current_level])

func _calc_xp_threshold(level: int) -> int:
	return xp_base * level
