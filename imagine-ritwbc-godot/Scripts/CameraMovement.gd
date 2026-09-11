extends Camera3D

@export_category("Movement Sensitivity")
@export_range(0.1, 1.0, 0.1) var pan_sensitivity: float = 0.5
@export_range(0.1, 1.0, 0.1) var zoom_sensitivity: float = 0.5

@export_category("Smoothing")
@export_range(1.0, 30.0, 0.5) var smoothing_speed: float = 12.0

@export_category("Map & Bounds")
@export var map: Sprite3D
@export var min_height: float = 2
@export var max_height: float = 20

const BASE_ZOOM_VALUE: float = 2.0
const BASE_PAN_VALUE: float = 0.05

var min_pos: Vector3
var max_pos: Vector3
var target_position: Vector3
var lastFramePos: Vector2 = Vector2.ZERO
var mouseDown: bool = false

func _ready() -> void:
	target_position = global_position
	
	update_map_bounds()
	set_zoom_max()
	
	initialize_input()
	
	ImGui.imgui_layout.connect(_on_layout)

func initialize_input():
	G_InputWrapper.on_press("mouse_pressed", set_mouse_down)
	G_InputWrapper.on_release("mouse_pressed", set_mouse_up)
	G_InputWrapper.on_press("zoom_in", zoom_in)
	G_InputWrapper.on_press("zoom_out", zoom_out)
	G_InputWrapper.on_press("escape", close_application)
	
func set_zoom_max():
	var world_aabb_map: AABB = map.global_transform * map.get_aabb()
	var fov_rad = deg_to_rad(self.fov)
	var distance = world_aabb_map.size.z / (2.0*tan(fov_rad / 2.0))
	max_height = distance
	

func close_application(_name):
	get_tree().quit(0);
	
#region Mouse Clamping

## Update the min and max position based on distance from mao
func update_map_bounds() -> void:
	if not map:
		return

	var world_aabb_map: AABB = map.global_transform * map.get_aabb()

	var d = get_distance_along_view(map.global_position)
	var visible_size = get_visible_size_at_distance(d)
	var half_visible = visible_size * 0.5

	# Shrink bounds inward by half the visible frustum size,
	# so the view edge stays within the map, not the camera position.
	min_pos = Vector3(
		world_aabb_map.position.x + half_visible.x,
		min_height,
		world_aabb_map.position.z + half_visible.y
	)
	max_pos = Vector3(
		world_aabb_map.end.x - half_visible.x,
		max_height,
		world_aabb_map.end.z - half_visible.y
	)

	# If the visible area is larger than the map (zoomed out far, or map small),
	# min > max would break clamp() — collapse to the map's center instead.
	if min_pos.x > max_pos.x:
		var cx = (world_aabb_map.position.x + world_aabb_map.end.x) * 0.5
		min_pos.x = cx
		max_pos.x = cx
	if min_pos.z > max_pos.z:
		var cz = (world_aabb_map.position.z + world_aabb_map.end.z) * 0.5
		min_pos.z = cz
		max_pos.z = cz

## Determine how much of the map the camera can see based on the current distance
func get_visible_size_at_distance(distance: float) -> Vector2:
	var fov_rad = deg_to_rad(self.fov)
	var height = 2.0 * distance * tan(fov_rad / 2.0)
	var aspect = get_viewport().get_visible_rect().size.x / get_viewport().get_visible_rect().size.y
	var width = height * aspect
	return Vector2(width, height)

## Get the distance from the camera to the map
func get_distance_along_view( target_pos: Vector3) -> float:
	var cam_basis_z = -self.global_transform.basis.z # forward
	var to_target = target_pos - self.global_transform.origin
	return to_target.dot(cam_basis_z)

#endregion

#region Mouse Input

func set_mouse_down(_name) -> void:
	mouseDown = true
	lastFramePos = get_viewport().get_mouse_position()

func set_mouse_up(_name) -> void:
	mouseDown = false

func zoom_in(_name) -> void:
	zoom_towards_mouse(-BASE_ZOOM_VALUE * zoom_sensitivity)

func zoom_out(_name) -> void:
	zoom_towards_mouse(BASE_ZOOM_VALUE * zoom_sensitivity)

## Zoom the camera in and out based on the mouse position
func zoom_towards_mouse(amount: float) -> void:
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var ray_dir: Vector3 = project_ray_normal(mouse_pos)
	
	# Ensure we have a non 0 value. Dividing by 0 breaks everything
	if abs(ray_dir.y) > 0.001:
		var zoom_step: Vector3 = ray_dir * (amount / ray_dir.y)
		target_position += zoom_step
	else:
		target_position.y += amount

	target_position = target_position.clamp(min_pos, max_pos)

#endregion

func _process(delta: float) -> void:
	if mouseDown:
		var current_mouse_pos := get_viewport().get_mouse_position()
		var frame_delta := current_mouse_pos - lastFramePos
		lastFramePos = current_mouse_pos

		var pan_offset := Vector3(frame_delta.x, 0.0, frame_delta.y) * BASE_PAN_VALUE * pan_sensitivity
		target_position += pan_offset
		target_position = target_position.clamp(min_pos, max_pos)
	
	global_position = global_position.lerp(target_position, delta * smoothing_speed).clamp(min_pos, max_pos)
	update_map_bounds();
	
func _on_layout():

	ImGui.set_next_window_size(600, 200, ImGui.COND_FIRST_USE_EVER);
	ImGui.begin("Camera Data")
	if(ImGui.collapsing_header("Camera Position")):
		ImGui.indent(20)
		ImGui.text("Camera Local Position: "+str(position))
		ImGui.text("Camera Global Position: "+str(global_position))
		ImGui.text("Camera Position Relative to Map: " + str(map.global_position-global_position))
		ImGui.unindent(20)
		
	if ImGui.collapsing_header("Camera Controls"):
		ImGui.indent(20)
		pan_sensitivity = ImGui.slider_float("Pan sensitivity", pan_sensitivity, .1, 1.0);
		zoom_sensitivity = ImGui.slider_float("Zoom sensitivity", zoom_sensitivity, .1, 1.0);
		smoothing_speed = ImGui.slider_float("Smoothing Speed", smoothing_speed, 1, 30);
		ImGui.unindent(20)
	
	ImGui.end()
	pass;
	
