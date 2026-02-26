class_name LandmarkPanel
extends PanelContainer

@export var name_label: RichTextLabel
@export var hp_bar: ProgressBar
@export var morale_bar: ProgressBar
@export var hp_label: RichTextLabel
@export var morale_label: RichTextLabel
@export var action_option: OptionButton
@export var action_desc: RichTextLabel

var unit: Unit
var selected_action := Landmark.LandmarkAction.NONE
var locked := false

func setup(u: Unit):
	unit = u

	name_label.text = u.unit_name

	hp_bar.max_value = u.max_hp
	hp_bar.value = u.current_hp
	hp_label.text = "%d/%d" % [u.current_hp, u.max_hp]

	morale_bar.max_value = u.max_morale
	morale_bar.value = u.current_morale
	morale_label.text = "%d/%d" % [u.current_morale, u.max_morale]

	_setup_actions()

func _setup_actions():
	action_option.clear()

	action_option.add_item("— Choose Action —", Landmark.LandmarkAction.NONE)
	action_option.add_item("Rest (Recover HP)", Landmark.LandmarkAction.REST_HP)
	action_option.add_item("Compose (Recover Morale)", Landmark.LandmarkAction.REST_MORALE)
	action_option.add_item("Prepare (Gain Buff)", Landmark.LandmarkAction.PREPARE)
	action_option.add_item("Explore Area", Landmark.LandmarkAction.EXPLORE)

	action_option.select(0)

	if not action_option.item_selected.is_connected(_on_action_selected):
		action_option.item_selected.connect(_on_action_selected)

func _on_action_selected(index: int):
	if locked:
		return

	selected_action = action_option.get_item_id(index)
	_update_action_description()

func _update_action_description():
	match selected_action:
		Landmark.LandmarkAction.REST_HP:
			action_desc.text = "Recover a portion of HP. Does not reduce exhaustion."
		Landmark.LandmarkAction.REST_MORALE:
			action_desc.text = "Recover morale. Fear effects are suppressed temporarily."
		Landmark.LandmarkAction.PREPARE:
			action_desc.text = "Gain a short-lived combat advantage. Increases exhaustion."
		Landmark.LandmarkAction.EXPLORE:
			action_desc.text = "Reveal information about the surrounding area. Risky."
		_:
			action_desc.text = ""

func lock():
	locked = true
	action_option.disabled = true
