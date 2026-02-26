extends Button
class_name MapNode

@export var before_node: Array[MapNode] = []
@export var map_ui:Control
var after_node: Array[MapNode] = []
var neighbor_node: Array[MapNode] = []
var manager:EventManager
var is_completed := false

signal completed

func _ready():
	add_to_group("MapNode")
	disabled = before_node.size() > 0

	# Register self as after_node
	for b in before_node:
		b.after_node.append(self)
		b.completed.connect(update_status)
	
	for n in get_parent().get_children():
		if n != self and n is MapNode: neighbor_node.append(n)

func complete():
	if is_completed:
		return
	is_completed = true
	disabled = true
	map_ui.visible=true
	completed.emit()
	print("[event] complete")

func update_status(): 
	if before_node.is_empty() and !is_completed:
		disabled=false
		return
	for b in before_node: 
		if b.is_completed: disabled = false

func _pressed():
	for n in neighbor_node: n.disabled=true
	map_ui.visible=false
	manager.current_event=self
	#complete()

func refresh():
	# Reset runtime state derived from graph
	disabled = true
	
	# Clear dynamic links (important if refresh is called more than once)
	after_node.clear()
	neighbor_node.clear()
	is_completed=false

	# Re-register dependencies
	for b in before_node:
		if not b.after_node.has(self):
			b.after_node.append(self)
		if not b.completed.is_connected(update_status):
			b.completed.connect(update_status)

	# Rebuild neighbors
	for n in get_parent().get_children():
		if n != self and n is MapNode:
			neighbor_node.append(n)

	# Recompute availability
	update_status()
