class_name FormationCard
extends PanelContainer

## =========================
## EXPECTED NODE STRUCTURE
## =========================
##
## FormationCard (PanelContainer)
## ├── Portrait (TextureRect)
## └── NameLabel (Label)
##
## Drag payload is the card's index in the party array.
## Drop target is any other FormationCard.

@export var portrait_rect: TextureRect
@export var name_label: RichTextLabel

var _index: int = -1
var _unit: Unit = null
var _party_manager: PartyManager = null

## Called by PartyManager._rebuild_formation_row() after instantiation.
func setup(unit: Unit, index: int, party_manager: PartyManager) -> void:
	_unit         = unit
	_index        = index
	_party_manager = party_manager

	name_label.text = unit.unit_name
	portrait_rect.texture = unit.portrait if unit.portrait else null

	# Cards need to accept drops from other cards.
	mouse_filter = Control.MOUSE_FILTER_STOP

## =========================
## DRAG AND DROP
## =========================

func _get_drag_data(_at_position: Vector2) -> Variant:
	# Preview: a faded copy of this card.
	var preview := Label.new()
	preview.text = _unit.unit_name
	set_drag_preview(preview)
	return _index


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	# Accept any integer that isn't our own index.
	return data is int and data != _index


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	# data = the from_index of the card being dropped onto us.
	_party_manager.reorder_unit(data, _index)
