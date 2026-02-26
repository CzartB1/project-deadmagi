class_name Landmark
extends MapNode

enum LandmarkAction {
	NONE,
	REST_HP,
	REST_MORALE,
	PREPARE,
	EXPLORE
}

@export var landmark_panel_scene: PackedScene
@export var panel_screen_offset := Vector2(0, -80)

var _panels: Array = []
@export var landmark_ui:Control
@export var _ui_layer: Control
@export var _formation_line: FormationLine3D
@export var _camera: Camera3D
@export var continue_button: Button
var _active := false

func _pressed():
	super._pressed()
	if _active:
		return
	if not continue_button.pressed.is_connected(_confirm_landmark):continue_button.pressed.connect(_confirm_landmark)
	_open_landmark()

# -------------------------
# Landmark Flow
# -------------------------

func _open_landmark():
	landmark_ui.visible=true
	_active = true
	_pause_expedition()
	_spawn_panels()
	#_play_landmark_idle()

func _confirm_landmark(): #TODO connect with buttons
	for panel in _panels:
		panel.lock()

	for panel in _panels:
		_execute_landmark_action(panel.unit, panel.selected_action)

	_close_landmark()
	complete()

func _execute_landmark_action(unit: Unit, action: int):
	
	match action:
		LandmarkAction.REST_HP:
			unit.receive_damage(-unit.max_hp * 0.25)
			#unit.add_exhaustion(-1)

		LandmarkAction.REST_MORALE:
			unit.restore_morale(unit.max_morale * 0.3)

		LandmarkAction.PREPARE:
			#unit.add_status("prepared", 2)
			print("[Landmark] %s prepares. NEED SOME STUFF HERE" % unit.unit_name)
			#unit.add_exhaustion(1)

		LandmarkAction.EXPLORE:
			#_reveal_map_info() TODO do some lore stuff here
			print("[Landmark] %s explores. NEED SOME STUFF HERE" % unit.unit_name)
			#unit.add_exhaustion(1)

		LandmarkAction.NONE:
			pass

func _close_landmark():
	_clear_panels()
	_resume_expedition()
	landmark_ui.visible=false
	_active = false

func _spawn_panels():
	_panels.clear()

	for unit in _formation_line.units:
		if unit == null or unit.model == null:
			continue

		var panel := landmark_panel_scene.instantiate()
		_ui_layer.add_child(panel)


		_panels.append(panel)
		if panel is LandmarkPanel: 
			panel.setup(unit)
			panel.unit=unit

func _clear_panels():
	for panel in _panels:
		if is_instance_valid(panel):
			panel.queue_free()
	_panels.clear()

# -------------------------
# Resolution
# -------------------------

func _resolve_actions() -> void:
	for panel in _panels:
		var unit = panel.unit
		var action = panel.selected_action
		if action:
			action.execute(unit, self)

#func _play_action_animations():
	#for panel in _panels:
		#var unit = panel.unit
		#if unit:
			#unit.play_landmark_action(panel.selected_action)
#
#func _play_landmark_idle():
	#for panel in _panels:
		#if panel.unit:
			#panel.unit.play_landmark_idle()

# -------------------------
# State / Control
# -------------------------

func _lock_ui():
	for panel in _panels:
		panel.lock()

func _pause_expedition():
	# freeze map movement, encounters, timers
	#get_tree().paused = true
	pass

func _resume_expedition():
	#get_tree().paused = false
	pass

func _all_actions_selected() -> bool:
	for panel in _panels:
		if panel.selected_action == LandmarkAction.NONE:
			return false
	return true
