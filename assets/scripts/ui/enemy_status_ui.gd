extends CanvasLayer

@export var u:Unit
@export var hp_bar:ProgressBar
@export var morale_bar:ProgressBar
@export var name_label:RichTextLabel
@export var status_label:RichTextLabel

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible=false
	u.setup_enemy_ui.connect(setup)
	u.damaged.connect(update_hp)
	u.morale_damaged.connect(update_morale)
	u.status_manager.status_update.connect(status_update)

func setup() -> void:
	visible=true
	name_label.text=u.unit_name
	hp_bar.max_value = u.max_hp
	hp_bar.value = u.current_hp
	#hp_label.text=str(unit.current_hp)+"/"+str(unit.max_hp)
	morale_bar.max_value = u.max_morale
	morale_bar.value = u.current_morale

func update_hp():
	hp_bar.max_value = u.max_hp
	hp_bar.value = u.current_hp

func update_morale():
	morale_bar.max_value = u.max_morale
	morale_bar.value = u.current_morale

func status_update():
	var text=""
	if u.bind_target != null:
		text += "\n[Dominance: %d]" % [
			u.dominance
		]
	
	if u.protector != null:
		text += "\n[protected by: %s | Protection: %d]" % [
			u.protector.unit_name,
			u.protector_timer
		]
	
	if u.status_manager.has_any():
		text += "\n" + u.status_manager.get_status_string()

	status_label.text = text
