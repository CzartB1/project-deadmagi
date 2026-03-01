extends Control
class_name TurnOrderItem

#@export var icon: TextureRect
@export var name_label: RichTextLabel
@export var background: PanelContainer
@export var highlight: PanelContainer
@export var hp_bar: ProgressBar
@export var morale_bar: ProgressBar

@export var ally_color: Color = Color(0.128, 0.139, 0.15, 1.0)
@export var enemy_color: Color = Color(0.15, 0.128, 0.128, 1.0)
#@export var active_color: Color = Color(0.15, 0.15, 0.128, 1.0)
@export var highlight_color: Color = Color(0.7, 0.7, 0.7, 1.0)
@export var damage_flash_color: Color = Color(1.0, 0.2, 0.2, 0.9)

@export var damage_anim_time := 0.18
@export var death_anim_time := 0.25

var unit: Unit
var base_color: Color
var dying := false
var damage_tween: Tween

func setup(u: Unit):
	#print("sdgnjo")
	unit = u
	name_label.text = u.unit_name
	#if u.is_ally: name_label.text = name_label.text+"\n["+str(u.current_level)+"]"
	#if u.has_method("get_icon"):
		#icon.texture = u.get_icon()

	base_color = ally_color if u.is_ally else enemy_color
	background.self_modulate = base_color
	highlight.self_modulate = highlight_color
	set_active(false)
	unit.damaged.connect(_on_unit_damaged)
	hp_bar.max_value=unit.max_hp
	hp_bar.value=unit.current_hp
	morale_bar.max_value=unit.max_morale
	morale_bar.value=unit.current_morale

func set_active(active: bool):
	highlight.visible = active
	#if active:
		#background.modulate = active_color
	#else:
		#background.modulate = base_color

func _process(_delta):
	if not dying and not is_instance_valid(unit):
		_on_unit_invalid()
	elif is_instance_valid(unit):
		morale_bar.value=unit.current_morale

func _on_unit_damaged():
	if dying:
		return

	if damage_tween:
		damage_tween.kill()
	
	hp_bar.value=unit.current_hp
	
	var flash_target := highlight if highlight.visible else background

	damage_tween = create_tween()

	# --- COLOR: SEQUENTIAL ---
	damage_tween.tween_property(
		flash_target,
		"self_modulate",
		damage_flash_color,
		damage_anim_time * 0.5
	)
	damage_tween.tween_property(
		flash_target,
		"self_modulate",
		base_color,
		damage_anim_time
	)
	scale = Vector2.ONE
	damage_tween.parallel().tween_property(
		self,
		"scale",
		Vector2(.9, .9),
		damage_anim_time * 0.4
	)
	damage_tween.parallel().tween_property(
		self,
		"scale",
		Vector2.ONE,
		damage_anim_time
	)

func _on_unit_invalid():
	dying = true
	highlight.visible = false
	if damage_tween: damage_tween.kill()
	var tween := create_tween()
	tween.parallel().tween_property(self, "self_modulate:a", 0.0, death_anim_time)
	tween.parallel().tween_property(self, "scale", Vector2(0.8, 0.8), death_anim_time)
	tween.tween_callback(queue_free)

func _exit_tree():
	if unit and unit.has_signal("damaged") and unit.damaged.is_connected(_on_unit_damaged):
		unit.damaged.disconnect(_on_unit_damaged)
	unit = null
