class_name UnitPanel
extends PanelContainer

@export var name_label: RichTextLabel
@export var hp_bar: ProgressBar
@export var morale_bar: ProgressBar
@export var hp_label: RichTextLabel
@export var morale_label: RichTextLabel

var unit: Unit
var dead := false
var _active_tween: Tween


func setup(u: Unit):
	unit = u
	unit.panel = self

	name_label.text = u.unit_name

	hp_bar.max_value = u.max_hp
	hp_bar.value = u.current_hp
	hp_label.text = "%d/%d" % [u.current_hp, u.max_hp]

	morale_bar.max_value = u.max_morale
	morale_bar.value = u.current_morale
	morale_label.text = "%d/%d" % [u.current_morale, u.max_morale]

	u.name_ready.connect(name_update)
	u.damaged.connect(update_hp)
	u.morale_damaged.connect(update_morale)

	u.attacked.connect(play_attack)
	u.damaged.connect(play_damage)
	u.died.connect(play_death)

	name_update()


# -------------------------------------------------------------------
# Name / Status
# -------------------------------------------------------------------
func name_update():
	if not is_instance_valid(unit):
		return

	var text := "[b]%s[/b]" % unit.unit_name

	if unit.bind_target:
		text += "\n[binded to: %s | Dominance: %d]" % [
			unit.bind_target.unit_name,
			unit.dominance
		]

	if unit.protector:
		text += "\n[protected by: %s | Protection: %d]" % [
			unit.protector.unit_name,
			unit.protector_timer
		]

	if unit.status_manager.has_any():
		text += "\n" + unit.status_manager.get_status_string()

	name_label.text = text


# -------------------------------------------------------------------
# HP / Morale
# -------------------------------------------------------------------
func update_hp():
	hp_bar.value = max(unit.current_hp, 0)
	hp_label.text = "%d/%d" % [unit.current_hp, unit.max_hp]


func update_morale():
	morale_bar.value = max(unit.current_morale, 0)
	morale_label.text = "%d/%d" % [unit.current_morale, unit.max_morale]


# -------------------------------------------------------------------
# Animations
# -------------------------------------------------------------------
func _kill_active_tweens():
	if _active_tween and _active_tween.is_running():
		_active_tween.kill()


func play_attack():
	_kill_active_tweens()
	_active_tween = create_tween() \
		.set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_OUT)

	_active_tween.tween_property(self, "scale", Vector2(1.08, 1.08), 0.12)
	_active_tween.tween_property(self, "scale", Vector2.ONE, 0.14)


func play_damage():
	_kill_active_tweens()
	_active_tween = create_tween()

	_active_tween.tween_property(self, "modulate", Color(1.0, 0.4, 0.4), 0.08)
	_active_tween.tween_property(self, "modulate", Color.WHITE, 0.18)


func play_death():
	if dead:
		return
	dead = true

	_kill_active_tweens()
	_active_tween = create_tween().set_ease(Tween.EASE_IN)

	_active_tween.tween_property(self, "modulate", Color(0.4, 0.4, 0.4), 0.25)
	_active_tween.tween_property(self, "position:x", position.x + 200, 0.35)
	_active_tween.tween_callback(queue_free)
