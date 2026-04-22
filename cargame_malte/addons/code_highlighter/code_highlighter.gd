@tool
extends EditorPlugin

const HighlightManager = preload("res://addons/code_highlighter/highlight_manager.gd")

var highlight_manager: HighlightManager

func _enter_tree() -> void:
	highlight_manager = HighlightManager.new()
	highlight_manager.editor_interface = get_editor_interface()
	add_child(highlight_manager)
	highlight_manager.initialize()
	print("[Code Block Highlighter] Plugin loaded.")

func _exit_tree() -> void:
	if highlight_manager:
		highlight_manager.cleanup()
		highlight_manager.queue_free()
	print("[Code Block Highlighter] Plugin unloaded.")
