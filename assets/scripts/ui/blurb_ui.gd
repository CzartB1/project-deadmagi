extends Node
class_name BlurbUI

@export var unit:Unit
@export var blurb_box: PanelContainer
@export var label: RichTextLabel
@export var visible_time := 2.5
var unit_id: String


func _ready():
	blurb_box.visible = false
	BlurbDirector.blurb_selected.connect(_on_blurb_selected)
	await get_tree().process_frame
	unit_id=unit.name+"_"+unit.unit_name


func _on_blurb_selected(intent: Dictionary) -> void:
	if intent.speaker != unit_id:
		#print("[blurb] fail to blurb ui visible bcs invalid id: ", unit_id, " != ", intent.speaker)
		return
	
	print("[blurb] making blurb ui visible")
	label.text = intent.text
	blurb_box.visible = true

	await get_tree().create_timer(visible_time).timeout
	blurb_box.visible = false
