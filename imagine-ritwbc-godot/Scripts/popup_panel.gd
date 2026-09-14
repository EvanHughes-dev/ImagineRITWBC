extends PanelContainer
class_name popup_panel
@onready var header_label: Label = $Margin/VBox/Header
@onready var body_label: Label = $Margin/VBox/Body

var target_ref: Node3D
var offset_3d: Vector3
var offset_screen: Vector2
var host_canvas: CanvasLayer
var _positioned := false

## Assign a new header and body text
func set_texts(header_text: String, body_text: String) -> void:
	header_label.text = header_text
	body_label.text = body_text

## Set variables for positioning in world
func setup(target: Node3D, w_offset: Vector3, s_offset: Vector2, canvas: CanvasLayer) -> void:
	target_ref = target
	offset_3d = w_offset
	offset_screen = s_offset
	host_canvas = canvas
	
	get_viewport().get_camera_3d().connect("camera_moved", camera_moved)

func camera_moved(camera: Camera3D, viewport_rect: Rect2):
	if not is_instance_valid(target_ref):
		PopupManager.close_popup(target_ref)
		return

	# Find the best fit for the panel relative to the camera and target point
	 
	
	var target_world_pos := target_ref.global_position + offset_3d
	
	var screen_pos := camera.unproject_position(target_world_pos)

	if not viewport_rect.has_point(screen_pos):
		visible = false
		return

	visible = true
	if size.y <= 0.0 and not _positioned:
		return
	_positioned = true

	global_position = screen_pos + Vector2(offset_screen.x, -size.y + offset_screen.y)

func _exit_tree() -> void:
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera.is_connected("camera_moved", camera_moved):
		camera.disconnect("camera_moved", camera_moved)
