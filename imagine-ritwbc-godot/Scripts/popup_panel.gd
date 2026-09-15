extends CanvasLayer
class_name PopupPanel3D

@onready var panel: PanelContainer = $PopupPanel
@onready var header_label: Label = $PopupPanel/Margin/VBox/Header
@onready var body_label: Label = $PopupPanel/Margin/VBox/Body

var target_ref: Node3D
var offset_3d: Vector3
var offset_screen: Vector2



## Assign a new header and body text
func set_texts(header_text: String, body_text: String) -> void:
	header_label.text = header_text
	body_label.text = body_text

## Set variables for positioning in world
func setup(target: Node3D, w_offset: Vector3 = Vector3.ZERO, s_offset: Vector2 = Vector2.ZERO) -> void:
	target_ref = target
	offset_3d = w_offset
	offset_screen = s_offset
	
	var view := get_viewport()
	view.get_camera_3d().connect("camera_moved", camera_moved)
	
	camera_moved(view.get_camera_3d(), view.get_visible_rect())

func camera_moved(camera: Camera3D, viewport_rect: Rect2):
	if not is_instance_valid(target_ref):
		visible = false
		return

	if not camera:
		visible = false
		return

	var target_world_pos := target_ref.global_position + offset_3d

	var screen_pos := camera.unproject_position(target_world_pos)

	if not viewport_rect.has_point(screen_pos):
		visible = false
		return

	visible = true
	panel.global_position = screen_pos + Vector2(offset_screen.x, -panel.size.y + offset_screen.y)
