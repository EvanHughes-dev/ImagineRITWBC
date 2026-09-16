extends CanvasLayer
class_name PopupPanel3D

@onready var panel: PanelContainer = $PopupPanel
@onready var header_label: Label = $PopupPanel/Margin/VBox/Header
@onready var body_label: Label = $PopupPanel/Margin/VBox/Body

var target_ref: Node3D
var offset_3d: Vector3
var offset_screen: Vector2

var target_pose: Vector2 = Vector2.ZERO

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
	var camera := view.get_camera_3d()
	camera.connect("camera_moved", camera_moved)
	panel.global_position = camera.unproject_position(target_ref.global_position) + Vector2(offset_screen.x, -panel.size.y - offset_screen.y)
	camera_moved(view.get_camera_3d(), view.get_visible_rect())
	 
## Called when the camera moved to update this panel's location
func camera_moved(camera: Camera3D, viewport_rect: Rect2):
	if not is_instance_valid(target_ref):
		visible = false
		return

	if not camera:
		visible = false
		return
	
	var screen_pos := camera.unproject_position(target_ref.global_position)
	
	# Default to the top left of the POI
	# Find the best corner for the panel to sit in
	
	# This value is in pixels from the top left of the screen
	var panel_rect := panel.get_global_rect()
	panel_rect.position = screen_pos + Vector2(offset_screen.x, -panel.size.y - offset_screen.y)
		
	if !viewport_rect.encloses(panel_rect):
		# Ok, now we know that top right isn't the best. Now time to find the best
		
		var panel_min := panel_rect.position
		var panel_max := panel_rect.position + panel_rect.size;
		var view_rect_min := viewport_rect.position;
		var view_rect_max := viewport_rect.position + viewport_rect.size
		
		if panel_max.x > view_rect_max.x:
			panel_rect.position.x = -panel_rect.size.x - offset_screen.x + screen_pos.x
		
		if panel_min.y < view_rect_min.y:
			panel_rect.position.y = offset_screen.y + screen_pos.y
	
	if !viewport_rect.intersects(panel_rect):
		PopupManager.close_popup(target_ref)
		
	target_pose = panel_rect.position
	visible = true

func _process(delta: float) -> void:
	# Move 30 pixels per second towards goal
	panel.global_position = panel.global_position.lerp(target_pose, delta*30) 
