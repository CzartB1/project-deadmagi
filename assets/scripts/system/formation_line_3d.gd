class_name FormationLine3D
extends Node3D

@export var spacing: float = 1.8
@export var direction: Vector3 = Vector3.RIGHT
@export var height: float = 0.0
@export var move_speed: float = 6.0

var units: Array[Unit] = []

func add_unit(unit: Unit, index := -1):
	if unit in units:
		return

	if index < 0 or index >= units.size():
		units.append(unit)
	else:
		units.insert(index, unit)

	unit.model.current_line = self
	for u in units:
		_reposition_units(false)

func remove_unit(unit: Unit):
	if unit not in units:
		return

	units.erase(unit)
	_reposition_units()

func _reposition_units(smooth:bool=true):
	var count := units.size()
	if count == 0:
		return

	var dir := direction.normalized()
	var total_width := (count - 1) * spacing
	var center_offset := total_width / 2.0

	for i in count:
		var unit := units[i]
		if !unit:
			units.erase(unit) 
			return
		if not unit.model:
			continue

		var offset := (i * spacing) - center_offset
		var target_pos := global_position \
			+ dir * offset \
			+ Vector3.UP * height
		
		if smooth:
			unit.model.move_to(target_pos)
		else:
			unit.model.global_position = target_pos
