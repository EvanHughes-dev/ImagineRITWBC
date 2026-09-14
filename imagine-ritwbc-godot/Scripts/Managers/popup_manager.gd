class_name PopupManager
extends Node

## Tracks one active popup CanvasLayer per target, so re-calling create_popup
## for the same target updates/reuses instead of stacking duplicates.
static var _active_popups: Dictionary = {} # Node3D -> CanvasLayer

const PopupPanelScene: PackedScene = preload("res://ui/popup_panel.tscn")

#region Popup Instances

## Create a new popup around the provided Node3D
static func create_popup(
	target: Node3D,
	header_text: String,
	body_text: String,
	world_offset: Vector3 = Vector3(0, 2.0, 0),
	screen_corner_offset: Vector2 = Vector2(15, -15)
) -> CanvasLayer:
	if not is_instance_valid(target):
		return null

	# Reuse/replace any existing popup for this target instead of stacking.
	close_popup(target)

	# 1. Screen Space Canvas
	var canvas_layer := CanvasLayer.new()
	canvas_layer.layer = 100
	target.get_tree().root.add_child(canvas_layer)

	# 2. Instantiate the pre-built popup scene (layout + real script already attached)
	var popup_box: popup_panel = PopupPanelScene.instantiate()
	canvas_layer.add_child(popup_box)

	popup_box.set_texts(header_text, body_text)
	popup_box.setup(target, world_offset, screen_corner_offset, canvas_layer)

	_active_popups[target] = canvas_layer
	return canvas_layer

## Explicitly close a popup for a given target (e.g. on deselect, click-away).
static func close_popup(target: Node3D) -> void:
	if not _active_popups.has(target):
		return
	var canvas: CanvasLayer = _active_popups[target]
	_active_popups.erase(target)
	if is_instance_valid(canvas):
		canvas.queue_free()

## Check if a Node3D already has a node assigned to it
static func has_popup(target: Node3D) -> bool:
	return _active_popups.has(target) and is_instance_valid(_active_popups[target])
#endregion
