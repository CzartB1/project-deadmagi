class_name Zone
extends Resource

@export var zone_name:String
@export var next_zones:Array[Zone]
@export_group("Difficulty Stages")
@export var baseline_stage: DifficultyStage
@export var distortion_stage: DifficultyStage
@export var desync_stage: DifficultyStage
@export var destabilization_stage: DifficultyStage
@export var fracture_stage: DifficultyStage
@export var cascade_stage: DifficultyStage
@export var convergence_stage: DifficultyStage
@export var singularity_stage: DifficultyStage

func setup():
	baseline_stage.display_name="Baseline"
	distortion_stage.display_name="Distortion"
	desync_stage.display_name="Desync"
	destabilization_stage.display_name="Destabilization"
	fracture_stage.display_name="Fracture"
	cascade_stage.display_name="Cascade"
	convergence_stage.display_name="Convergence"
	singularity_stage.display_name="Singularity"

func get_stages() -> Array[DifficultyStage]:
	return [
		baseline_stage,
		distortion_stage,
		desync_stage,
		destabilization_stage,
		fracture_stage,
		cascade_stage,
		convergence_stage,
		singularity_stage
	]
