extends CanvasLayer
class_name NotificationManager

# =========================
# ENUMS
# =========================

enum Tag {
	NONE,
	COMBAT,
	DAMAGE,
	MORALE,
	STATUS,
	XP,
	SYSTEM
}

# =========================
# CONSTANTS
# =========================

const MAX_PRIORITY_ENTRIES := 3
const PRIORITY_DURATION    := 3.0   # seconds before fade begins
const FADE_DURATION        := 0.6   # seconds to fade out

const TAG_COLORS := {
	Tag.COMBAT:  "#E87B3A",
	Tag.DAMAGE:  "#D94444",
	Tag.MORALE:  "#E8C13A",
	Tag.STATUS:  "#7FD944",
	Tag.XP:      "#44D4E8",
	Tag.SYSTEM:  "#6A9FBF",
}

const TAG_LABELS := {
	Tag.COMBAT:  "COMBAT",
	Tag.DAMAGE:  "DAMAGE",
	Tag.MORALE:  "MORALE",
	Tag.STATUS:  "STATUS",
	Tag.XP:      "XP",
	Tag.SYSTEM:  "SYSTEM",
}

# =========================
# EXPORTS
# =========================

@export var priority_container: VBoxContainer
@export var history_container: VBoxContainer
@export var history_panel: Control          # the panel/scroll container wrapping history
@export var toggle_history_action: String = "toggle_history"   # InputMap action name

@export var priority_font_size: int = 18
@export var history_font_size:  int = 13

# =========================
# LIFECYCLE
# =========================

func _ready():
	if history_panel:
		history_panel.visible = false

func _unhandled_input(event: InputEvent):
	if event.is_action_pressed(toggle_history_action):
		toggle_history()

# =========================
# PUBLIC API
# =========================

## Main entry point. Call from anywhere.
## priority=true  → shows in priority container AND logs to history
## priority=false → logs to history only
func notify(text: String, tag: Tag = Tag.NONE, priority: bool = false):
	var formatted_history  := _format_history(text, tag)
	var formatted_priority := _format_priority(text, tag)

	_add_to_history(formatted_history)

	if priority:
		_add_to_priority(formatted_priority)

func toggle_history():
	if history_panel:
		history_panel.visible = not history_panel.visible

func clear_history():
	for child in history_container.get_children():
		child.queue_free()

# =========================
# PRIORITY CONTAINER
# =========================

func _add_to_priority(bbcode: String):
	# If full, remove the oldest (first child)
	while priority_container.get_child_count() >= MAX_PRIORITY_ENTRIES:
		var oldest := priority_container.get_child(0)
		oldest.queue_free()

	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	label.text = bbcode
	label.add_theme_font_size_override("normal_font_size", priority_font_size)
	label.modulate.a = 1.0

	priority_container.add_child(label)

	# Start the timer then fade
	var tween := create_tween()
	tween.tween_interval(PRIORITY_DURATION)
	tween.tween_property(label, "modulate:a", 0.0, FADE_DURATION)
	tween.tween_callback(label.queue_free)

# =========================
# HISTORY CONTAINER
# =========================

func _add_to_history(bbcode: String):
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.text = bbcode
	label.add_theme_font_size_override("normal_font_size", history_font_size)

	history_container.add_child(label)

	# Auto-scroll to bottom
	var scroll := history_container.get_parent()
	if scroll is ScrollContainer:
		await get_tree().process_frame
		scroll.scroll_vertical = scroll.get_v_scroll_bar().max_value

# =========================
# FORMATTING
# =========================

func _format_tag_bbcode(tag: Tag) -> String:
	if tag == Tag.NONE:
		return ""
	var color = TAG_COLORS.get(tag, "#FFFFFF")
	var label = TAG_LABELS.get(tag, "")
	return "[color=%s][%s][/color] " % [color, label]

func _format_history(text: String, tag: Tag) -> String:
	return _format_tag_bbcode(tag) + "[color=#FFFFFF]" + text + "[/color]"

func _format_priority(text: String, tag: Tag) -> String:
	return _format_tag_bbcode(tag) + "[color=#FFFFFF]" + text + "[/color]"
