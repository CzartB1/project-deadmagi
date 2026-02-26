extends PanelContainer
class_name UnitPreviewEntry

@export var name_edit: LineEdit 
@export var ally_toggle: CheckBox 
@export var remove_button: Button 

var unit: Unit
var on_remove: Callable

func setup(u: Unit, remove_cb: Callable):
	unit = u
	on_remove = remove_cb

	name_edit.text = unit.unit_name
	ally_toggle.button_pressed = unit.is_ally

	name_edit.text_changed.connect(_on_name_changed)
	ally_toggle.toggled.connect(_on_ally_toggled)
	remove_button.pressed.connect(_on_remove_pressed)

func _on_name_changed(text: String):
	unit.unit_name = text.strip_edges()

func _on_ally_toggled(value: bool):
	unit.is_ally = value

func _on_remove_pressed():
	on_remove.call(self, unit)
