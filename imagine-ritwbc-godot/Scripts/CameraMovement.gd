extends Camera3D

@export_category("Movement Sensitivity")
@export_range(0.1, 1.0, 0.1) var pan_sensitivity: float = 0.5
@export_range(0.1, 1.0, 0.1) var zoom_sensitivity: float = 0.5

@export_category("Smoothing")
@export_range(1.0, 30.0, 0.5) var smoothing_speed: float = 12.0

@export_category("Map & Bounds")
@export var map: Sprite3D

@onready var world_aabb_map: AABB = map.global_transform * map.get_aabb()
@export var min_pos: Vector3
@export var max_pos: Vector3

const BASE_ZOOM_VALUE: float = 2.0
const BASE_PAN_VALUE: float = 0.05

var target_position: Vector3

var mouseDown: bool = false
var display_debug: bool = false;

signal camera_moved;

## Get the current aspect ratio
var aspect: float:
	get():
		var viewport_size: = get_viewport().get_visible_rect().size
		return viewport_size.x / viewport_size.y;

func _ready() -> void:
	
	# var win = SeparateWindow.new()
	# add_child(win)
	# win.open_window("Sub Window", 100, 100)
	
	target_position = global_position
	target_position.y = size
	
	update_map_bounds()
	set_zoom_max()
	
	initialize_input()
	
	LimboConsole.register_command(_toggle_gui, "debug_camera", "toggle camera debug on and off")

func _process(delta: float) -> void:
	if !target_position.is_equal_approx(global_position):
		# Smoothly interpolate height size
		size = lerpf(size, target_position.y, delta * smoothing_speed)
		
		# Smoothly interpolate position and clamp against bounds for the CURRENT smoothed size
		var current_bounds := get_bounds_for_height(size)
		var lerped_pos := global_position.lerp(target_position, delta * smoothing_speed)
		global_position = lerped_pos.clamp(current_bounds["min"], current_bounds["max"])
		
		camera_moved.emit(self, get_viewport().get_visible_rect())

func initialize_input():
	G_InputWrapper.on_press("mouse_pressed", set_mouse_down)
	G_InputWrapper.on_release("mouse_pressed", set_mouse_up)
	G_InputWrapper.on_press("zoom_in", zoom_in)
	G_InputWrapper.on_press("zoom_out", zoom_out)
	G_InputWrapper.on_press("escape", close_application)
	G_InputWrapper.on_mouse_move(move_moused)

## On mouse move, move camera if needed
func move_moused(_frmae_dstance: float, frame_delta: Vector2) -> void:
	if mouseDown:
		# Scale panning relative to current zoom level (smaller size = slower pan)
		var zoom_factor: float = target_position.y / max_pos.y
		var pan_offset := Vector3(frame_delta.x, 0.0, frame_delta.y) * BASE_PAN_VALUE * pan_sensitivity * zoom_factor
		
		target_position += pan_offset
		
		# Clamp target position against target bounds
		var target_bounds := get_bounds_for_height(target_position.y)
		target_position = target_position.clamp(target_bounds["min"], target_bounds["max"])	

func close_application(_name):
	get_tree().quit(0);

func zoom_poi(poi_target: poi):
	zoom_to_point(poi_target.global_position, 2.0)
	pass;
	
func zoom_to_point(new_target: Vector3, new_size: float) -> void:
	if is_zero_approx(target_position.y):
		return

	# Move directly to the new target's X/Z coordinates at the new height
	var new_pos: Vector3 = Vector3(new_target.x, new_size, new_target.z)

	# Clamp using height-specific bounds to prevent edge popping
	var target_bounds := get_bounds_for_height(new_size)
	target_position = new_pos.clamp(target_bounds["min"], target_bounds["max"])

#region Mouse Input

## Set mouse as down and detect poi press
func set_mouse_down(_name) -> void:
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var ray_origin: Vector3 = project_ray_origin(mouse_pos)
	var ray_dir: Vector3 = project_ray_normal(mouse_pos)
	var ground_y: float = map.global_position.y if map else 0.0

	var mousePosMap: = find_map_pos_of_mouse(ground_y, ray_origin, ray_dir)
	
	var space_state = get_world_3d().direct_space_state
	var query: = PhysicsRayQueryParameters3D.create(ray_origin, mousePosMap, 2, []); 
	var result: = space_state.intersect_ray(query)
	
	if result != {}:
		var parent:=(result.collider as Node3D).get_parent_node_3d()
		if parent is poi:
			parent.pressed()
			zoom_poi(parent)
			pass;
	
	mouseDown = true

func set_mouse_up(_name) -> void:
	mouseDown = false

func zoom_in(_name) -> void:
	zoom_towards_mouse(-BASE_ZOOM_VALUE * zoom_sensitivity)

func zoom_out(_name) -> void:
	zoom_towards_mouse(BASE_ZOOM_VALUE * zoom_sensitivity)

## Zoom the camera in and out based on the mouse position
func zoom_towards_mouse(amount: float) -> void:
	var old_size: float = target_position.y
	var new_size: float = clampf(old_size + amount, min_pos.y, max_pos.y)

	if is_zero_approx(new_size - old_size):
		return

	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var ray_origin: Vector3 = project_ray_origin(mouse_pos)
	var ray_dir: Vector3 = project_ray_normal(mouse_pos)

	# Avoid division by zero if camera looks parallel to ground
	if abs(ray_dir.y) < 0.001:
		target_position.y = new_size
		return

	# Target plane height (samples map Y position if assigned, otherwise 0.0)
	var ground_y: float = map.global_position.y if map else 0.0

	# Prevent division by zero if camera target is on the ground plane
	if is_zero_approx(old_size - ground_y):
		target_position.y = new_size
		return
	
	# calculate zoom
	var new_target := find_map_pos_of_mouse(ground_y, ray_origin, ray_dir)

	if is_zero_approx(target_position.y):
		return

	# Scale target position outward/inward from the ground point under the cursor
	var scale_factor: float = new_size / target_position.y
	var new_pos: Vector3 = new_target + (target_position - new_target) * scale_factor
	new_pos.y = new_size

	# Clamp using height-specific bounds to prevent edge popping
	var target_bounds := get_bounds_for_height(new_size)
	target_position = new_pos.clamp(target_bounds["min"], target_bounds["max"])

## Find the Vector3 position of the mouse on the map below
func find_map_pos_of_mouse(ground_y: float, ray_origin: Vector3, ray_dir: Vector3)->Vector3:
	var t: float = (ground_y - ray_origin.y) / ray_dir.y
	return ray_origin + ray_dir * t
#endregion

#region Mouse Clamping

## Returns min and max Vector3 bounds calculated for a specific camera size
func get_bounds_for_height(target_h: float) -> Dictionary:
	if not map:
		return {"min": min_pos, "max": max_pos}

	var visible_size := get_visible_size_at_height(target_h)
	var half_visible := visible_size * 0.5

	var calculated_min := Vector3(
		world_aabb_map.position.x + half_visible.x,
		min_pos.y,
		world_aabb_map.position.z + half_visible.y
	)
	var calculated_max := Vector3(
		world_aabb_map.end.x - half_visible.x,
		max_pos.y,
		world_aabb_map.end.z - half_visible.y
	)

	if calculated_min.x > calculated_max.x:
		var cx := (world_aabb_map.position.x + world_aabb_map.end.x) * 0.5
		calculated_min.x = cx
		calculated_max.x = cx
	if calculated_min.z > calculated_max.z:
		var cz := (world_aabb_map.position.z + world_aabb_map.end.z) * 0.5
		calculated_min.z = cz
		calculated_max.z = cz

	return {"min": calculated_min, "max": calculated_max}

## Update the min and max position based on distance from mao
func update_map_bounds() -> void:
	if not map:
		return

	var visible_size = get_visible_size()
	var half_visible = visible_size * 0.5

	# Shrink bounds inward by half the visible frustum size,
	# so the view edge stays within the map, not the camera position.
	min_pos = Vector3(
		world_aabb_map.position.x + half_visible.x,
		2.0,
		world_aabb_map.position.z + half_visible.y
	)
	max_pos = Vector3(
		world_aabb_map.end.x - half_visible.x,
		max_pos.y,
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

## Set the max zoom value for camera
func set_zoom_max():
	
	var visible_size: Vector2 = get_visible_size()
		
	# Determine % of how to zoom out before reaching bounds
	var xMult: float = world_aabb_map.size.x / visible_size.x
	var yMult: float = world_aabb_map.size.z / visible_size.y
	
	# Set heights based on mult value
	# Smaller value is the lowest scale to increase
	if xMult < yMult:
		if keep_aspect == KEEP_HEIGHT:
			max_pos.y = size * xMult / aspect
		else:
			max_pos.y = size * xMult
	else:
		if keep_aspect == KEEP_HEIGHT:
			max_pos.y = size * yMult
		else:
			max_pos.y = size * yMult * aspect

## Determine how much of the map the camera can see
func get_visible_size() -> Vector2:
	var camSize: Vector2;
	if keep_aspect == KEEP_HEIGHT:
		camSize = Vector2(size * aspect, size);
		pass;
	else:
		camSize = Vector2(size, size/aspect)
		pass;
	return camSize

## Determine how much of the map the camera can see for a given size height
func get_visible_size_at_height(custom_size: float = -1.0) -> Vector2:
	var h: float = custom_size if custom_size > 0.0 else size
	if keep_aspect == KEEP_HEIGHT:
		return Vector2(h * aspect, h)
	else:
		return Vector2(h, h / aspect)

#endregion

#region Debugging
func _toggle_gui():
	display_debug = !display_debug;
	if display_debug:
		ImGui.imgui_layout.connect(_on_layout)
	elif ImGui.imgui_layout.is_connected(_on_layout):
		ImGui.imgui_layout.disconnect(_on_layout)

## Create GUI indatnce for debugging camer values
func _on_layout():
	ImGui.set_next_window_size(0, 0, ImGui.COND_ALWAYS)

	ImGui.begin("Camera Data")
	if(ImGui.collapsing_header("Camera Position")):
		ImGui.indent(20)
		ImGui.text("Camera Local Position: "+str(position))
		ImGui.text("Camera Global Position: "+str(global_position))
		
		# Get location relative
		
		var map_center_global: Vector3 = map.global_position + world_aabb_map.get_center()
		var pos_relative_to_center: Vector3 = global_position - map_center_global

		ImGui.text("Camera Position Relative to Map Center: " + str(pos_relative_to_center))

		# Calculate true geometric center and total size
		var bounds_center: Vector3 = (max_pos + min_pos) / 2.0
		var bounds_size: Vector3 = (max_pos - min_pos).abs()

		# Offset from center
		var offset_from_center: Vector3 = global_position - bounds_center

		# Normalize to [-1, 1] range (Offset / Half_Size)
		var half_size: Vector3 = bounds_size / 2.0
		var pos_relative_to_bounds: Vector3 = offset_from_center / half_size

		ImGui.text("Camera Position Relative to Bounds: " + str(pos_relative_to_bounds))
		if ImGui.is_item_hovered(ImGui.HOVERED_RECT_ONLY):
			ImGui.begin_tooltip()
			ImGui.text("Scale from -1 to 1")
			ImGui.text("-1 is at min_pos, 0 is center, 1 is max pos")
			ImGui.end_tooltip()

		ImGui.unindent(20)
		
	if ImGui.collapsing_header("Camera Controls"):
		ImGui.indent(20)
		pan_sensitivity = ImGui.slider_float("Pan sensitivity", pan_sensitivity, .1, 1.0);
		zoom_sensitivity = ImGui.slider_float("Zoom sensitivity", zoom_sensitivity, .1, 1.0);
		smoothing_speed = ImGui.slider_float("Smoothing Speed", smoothing_speed, 1, 30);
		ImGui.unindent(20)
	
	if ImGui.collapsing_header("Camera Bounds"):
		ImGui.indent(20)
		ImGui.text("Camera Position Bounds: "+str(min_pos) +" - "+ str(max_pos))
		ImGui.text("Camera Size Bounds: "+str(min_pos.y) + " - " + str(max_pos.y))
		ImGui.unindent(20)
	ImGui.end()

#endregion
