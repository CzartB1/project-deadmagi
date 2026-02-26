class_name UnitModel3D
extends Node3D

@export var mesh:MeshInstance3D
@export var unit: Unit
@export var crit_cam: PhantomCamera3D
var current_line: FormationLine3D

var _target_position: Vector3

func _ready():
	_target_position = global_position
	crit_cam.priority=0

func move_to(pos: Vector3):
	_target_position = pos

func _physics_process(delta):
	global_position = global_position.lerp(
		_target_position,
		delta * 6.0
	)

func move_action(target_pos:Vector3, crit_cam_zoom:bool=false):
	if crit_cam_zoom: crit_cam.set_priority(10)
	var tween = create_tween()
	tween.tween_property(mesh, "global_position", global_position.lerp(target_pos,0.8), 0.15)
	await get_tree().create_timer(.35).timeout
	var tween2 = create_tween()
	tween2.tween_property(mesh, "global_position", global_position, 0.3)
	if crit_cam_zoom: crit_cam.set_priority(0)

func reset_model_pos():
	#current_line._reposition_units()
	if !unit.bind_target:
		var tween3 = create_tween()
		tween3.tween_property(mesh, "global_position", global_position, 0.3)
	if current_line: current_line._reposition_units()
