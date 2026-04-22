@tool
extends Node

## Manages code block highlights across all open script editors.
## Hooks into each CodeEdit via a draw overlay on a Control node.
## Highlights are persisted to .godot/editor/code_highlights.json

var editor_interface: EditorInterface

# { script_path: [ {from_line, to_line, color} ] }
var highlights: Dictionary = {}

# Track which CodeEdit nodes we've already hooked
var hooked_editors: Array = []

const SAVE_PATH := "res://.godot/editor/code_highlights.json"

# Colors available in the right-click menu
const HIGHLIGHT_COLORS := {
	"🟢 Green":    Color(0.20, 0.80, 0.20, 0.25),
	"🔵 Blue":     Color(0.20, 0.50, 1.00, 0.25),
	"🟡 Yellow":   Color(1.00, 0.90, 0.10, 0.28),
	"🔴 Red":      Color(1.00, 0.25, 0.25, 0.25),
	"🟠 Orange":   Color(1.00, 0.55, 0.10, 0.25),
	"🟣 Purple":   Color(0.75, 0.25, 1.00, 0.25),
	"🩷 Pink":     Color(1.00, 0.45, 0.75, 0.25),
	"⬜ Clear":    Color(0, 0, 0, 0),
}

var _poll_timer: Timer
# Pending selection info used when the popup menu triggers
var _pending_code_edit: CodeEdit = null
var _pending_from_line: int = -1
var _pending_to_line: int = -1

# ------------------------------------------------------------------
#  Init / Cleanup
# ------------------------------------------------------------------

func initialize() -> void:
	_load_highlights()
	_poll_timer = Timer.new()
	_poll_timer.wait_time = 0.8
	_poll_timer.autostart = true
	_poll_timer.connect("timeout", _poll_script_editors)
	add_child(_poll_timer)
	_poll_script_editors()

func cleanup() -> void:
	_save_highlights()
	if _poll_timer:
		_poll_timer.stop()
	for entry in hooked_editors:
		var overlay = entry.get("overlay")
		if is_instance_valid(overlay):
			overlay.queue_free()
	hooked_editors.clear()

# ------------------------------------------------------------------
#  Persistence – save/load JSON
# ------------------------------------------------------------------

func _save_highlights() -> void:
	# Build a serialisable structure: colors stored as hex strings
	var data: Dictionary = {}
	for path in highlights.keys():
		var arr: Array = []
		for h in highlights[path]:
			arr.append({
				"from":  h["from"],
				"to":    h["to"],
				"color": "#" + h["color"].to_html(true)
			})
		if arr.size() > 0:
			data[path] = arr

	# Ensure the directory exists
	var dir := DirAccess.open("res://")
	if dir:
		if not dir.dir_exists(".godot/editor"):
			dir.make_dir_recursive(".godot/editor")

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
	else:
		push_warning("[Code Block Highlighter] Could not save highlights to: " + SAVE_PATH)

func _load_highlights() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		push_warning("[Code Block Highlighter] Could not read highlights from: " + SAVE_PATH)
		return

	var text := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("[Code Block Highlighter] Highlight file is malformed.")
		return

	highlights.clear()
	for path in parsed.keys():
		var arr: Array = []
		for entry in parsed[path]:
			arr.append({
				"from":  int(entry["from"]),
				"to":    int(entry["to"]),
				"color": Color(entry["color"])
			})
		highlights[path] = arr

	print("[Code Block Highlighter] Loaded highlights for %d file(s)." % highlights.size())

# ------------------------------------------------------------------
#  Polling – find new CodeEdit widgets inside ScriptEditor
# ------------------------------------------------------------------

func _poll_script_editors() -> void:
	var script_editor := editor_interface.get_script_editor()
	if not script_editor:
		return
	_recurse_for_code_edits(script_editor)

func _recurse_for_code_edits(node: Node) -> void:
	if node is CodeEdit:
		_try_hook_code_edit(node as CodeEdit)
	for child in node.get_children():
		_recurse_for_code_edits(child)

func _try_hook_code_edit(ce: CodeEdit) -> void:
	# Already hooked?
	for entry in hooked_editors:
		if entry.get("code_edit") == ce:
			return

	# Create a transparent overlay Control that sits on top of the CodeEdit
	var overlay := _OverlayControl.new()
	overlay.code_edit = ce
	overlay.manager = self
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Add as sibling so it doesn't interfere with the CodeEdit's own input
	ce.get_parent().add_child(overlay)

	# Connect right-click (gui_input on the CodeEdit)
	ce.connect("gui_input", _on_code_edit_gui_input.bind(ce))

	hooked_editors.append({"code_edit": ce, "overlay": overlay})

# ------------------------------------------------------------------
#  Right-click context menu
# ------------------------------------------------------------------

func _on_code_edit_gui_input(event: InputEvent, ce: CodeEdit) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			if not ce.has_selection():
				return
			_pending_code_edit = ce
			_pending_from_line = ce.get_selection_from_line()
			_pending_to_line   = ce.get_selection_to_line()
			_pending_popup_pos = mb.global_position

			# Close any hover/autocomplete popups by hiding all popups in the tree
			_close_all_popups(get_tree().root)

			# Wait 2 frames — one for the CodeEdit to process its own right-click,
			# one more to ensure the hover tooltip/docs popup has fully closed.
			await get_tree().process_frame
			await get_tree().process_frame
			_show_color_popup()

var _pending_popup_pos: Vector2 = Vector2.ZERO

func _close_all_popups(node: Node) -> void:
	if node is Popup and node.visible:
		# Don't close our own menu if somehow it's already open
		if node.name != "CodeHighlighterMenu":
			(node as Popup).hide()
	for child in node.get_children():
		_close_all_popups(child)

func _show_color_popup() -> void:
	var popup := PopupMenu.new()
	popup.name = "CodeHighlighterMenu"

	var idx := 0
	for label in HIGHLIGHT_COLORS.keys():
		popup.add_item(label, idx)
		idx += 1

	get_tree().root.add_child(popup)
	popup.connect("id_pressed", _on_color_selected.bind(popup))
	popup.connect("popup_hide", popup.queue_free)
	popup.position = Vector2i(int(_pending_popup_pos.x), int(_pending_popup_pos.y))
	popup.popup()

func _on_color_selected(id: int, popup: PopupMenu) -> void:
	var label: String = popup.get_item_text(id)
	var color: Color  = HIGHLIGHT_COLORS[label]

	if not is_instance_valid(_pending_code_edit):
		return

	var ce   := _pending_code_edit
	var from := _pending_from_line
	var to   := _pending_to_line

	var script_path := _get_script_path(ce)

	if color.a == 0.0:
		# "Clear" – remove any highlights that overlap the selection
		_remove_highlights_in_range(script_path, from, to)
	else:
		_add_highlight(script_path, ce, from, to, color)

	_save_highlights()
	_refresh_overlay_for(ce)

# ------------------------------------------------------------------
#  Highlight data management
# ------------------------------------------------------------------

func _get_script_path(ce: CodeEdit) -> String:
	# Walk up to find ScriptEditorBase and grab its script resource path
	var node: Node = ce.get_parent()
	while node:
		if node.has_method("get_edited_resource"):
			var res = node.call("get_edited_resource")
			if res and res.resource_path != "":
				return res.resource_path
		node = node.get_parent() if node.get_parent() != node else null
	# Fallback: use the instance id so highlights still work in-session
	return "@@%d" % ce.get_instance_id()

func _add_highlight(path: String, ce: CodeEdit, from: int, to: int, color: Color) -> void:
	if not highlights.has(path):
		highlights[path] = []
	# Remove any existing highlight that fully overlaps same range
	_remove_highlights_in_range(path, from, to)
	highlights[path].append({"from": from, "to": to, "color": color})

func _remove_highlights_in_range(path: String, from: int, to: int) -> void:
	if not highlights.has(path):
		return
	var kept: Array = []
	for h in highlights[path]:
		# Keep if completely outside the cleared range
		if h["to"] < from or h["from"] > to:
			kept.append(h)
	highlights[path] = kept

func get_highlights_for(ce: CodeEdit) -> Array:
	var path := _get_script_path(ce)
	return highlights.get(path, [])

func _refresh_overlay_for(ce: CodeEdit) -> void:
	for entry in hooked_editors:
		if entry.get("code_edit") == ce:
			var overlay = entry.get("overlay")
			if is_instance_valid(overlay):
				overlay.queue_redraw()
			return

# ------------------------------------------------------------------
#  Inner class: transparent overlay that draws the highlight rects
# ------------------------------------------------------------------

class _OverlayControl extends Control:
	var code_edit: CodeEdit
	var manager: Node   # the HighlightManager

	const BORDER_W    := 3.0   # px — solid opaque border thickness
	const H_PAD       := 4.0   # px — horizontal padding beyond last glyph
	const MIN_WIDTH   := 40.0  # px — minimum highlight width so tiny lines look ok

	func _ready() -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(_delta: float) -> void:
		if is_instance_valid(code_edit):
			global_position = code_edit.global_position
			size = code_edit.size
			queue_redraw()

	func _draw() -> void:
		if not is_instance_valid(code_edit):
			return
		var hl_list: Array = manager.get_highlights_for(code_edit)
		if hl_list.is_empty():
			return

		var line_height: float = code_edit.get_line_height()
		var total_lines: int   = code_edit.get_line_count()
		var first_visible: int = code_edit.get_first_visible_line()
		var visible_rows: int  = int(code_edit.size.y / line_height) + 2

		# X offset where text starts (accounts for line-number gutter)
		var text_x: float = _get_text_x_offset()

		for h in hl_list:
			var from_line: int = clampi(h["from"], 0, total_lines - 1)
			var to_line:   int = clampi(h["to"],   0, total_lines - 1)
			var color: Color   = h["color"]
			var border_color   = Color(color.r, color.g, color.b, 1.0)

			if to_line < first_visible or from_line > first_visible + visible_rows:
				continue

			# Find the widest line in the block so the box has a consistent right edge
			var max_right: float = MIN_WIDTH
			for line in range(from_line, to_line + 1):
				var w: float = _get_line_text_width(line)
				if w > max_right:
					max_right = w
			max_right += text_x + H_PAD

			# Draw fill + border for the whole block as one rectangle
			var top_y:    float = _get_line_y(from_line)
			var bot_y:    float = _get_line_y(to_line) + line_height
			var block := Rect2(text_x, top_y, max_right - text_x, bot_y - top_y)

			draw_rect(block, color)
			draw_rect(block, border_color, false, BORDER_W)

	# ---- helpers -------------------------------------------------------

	func _get_text_x_offset() -> float:
		# The gutter (line numbers) width — use get_total_gutter_width if available,
		# otherwise fall back to querying position of column 0 on line 0.
		if code_edit.has_method("get_total_gutter_width"):
			return float(code_edit.get_total_gutter_width())
		# Fallback: get_line_column_height not available, estimate via font
		return 0.0

	func _get_line_text_width(line: int) -> float:
		# Measure the pixel width of the text on this line using the CodeEdit's font.
		var font: Font = code_edit.get_theme_font("font")
		var font_size: int = code_edit.get_theme_font_size("font_size")
		if not font:
			return MIN_WIDTH
		var text: String = code_edit.get_line(line)
		# Strip trailing whitespace so the box hugs actual content
		text = text.rstrip(" \t")
		if text.is_empty():
			return MIN_WIDTH
		return font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x

	func _get_line_y(line: int) -> float:
		var line_height: float = code_edit.get_line_height()
		var first_vis: int = code_edit.get_first_visible_line()
		var visual_row: int = 0
		for l in range(first_vis, line):
			visual_row += 1 + code_edit.get_line_wrap_count(l)
		var frac_offset: float = 0.0
		if code_edit.get_v_scroll_bar() and code_edit.get_v_scroll_bar().has_method("get_value"):
			var scroll_val: float = code_edit.get_v_scroll_bar().value
			frac_offset = fmod(scroll_val, 1.0) * line_height
		return visual_row * line_height - frac_offset
