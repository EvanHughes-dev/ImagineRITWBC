extends Camera3D

signal camera_moved

@export_category("Target Settings")
@export var target_node: Node3D
@export var target_offset: Vector3 = Vector3.ZERO

@export_category("Movement Sensitivity")
@export_range(0.001, 0.02, 0.001) var orbit_sensitivity: float = 0.005
@export_range(0.5, 10.0, 0.5) var zoom_sensitivity: float = 2.0

@export_category("Smoothing")
@export_range(1.0, 30.0, 0.5) var smoothing_speed: float = 12.0

@export_category("Orbit Limits")
@export var min_distance: float = 2.0
@export var max_distance: float = 100.0

@export var debug_line: PackedScene;

var new_debug_line: MeshInstance3D;

# Yay! Quaternions! Time to understand none of the math!
var target_orientation: Quaternion = Quaternion.IDENTITY
var current_orientation: Quaternion = Quaternion.IDENTITY

var target_distance: float = 10.0
var current_distance: float = 10.0

var target_focus_point: Vector3 = Vector3.ZERO
var current_focus_point: Vector3 = Vector3.ZERO

var is_orbiting: bool = false
var display_debug: bool = false


func _ready() -> void:
	if target_node:
		target_focus_point = target_node.global_position + target_offset
	else:
		target_focus_point = global_position + global_transform.basis.z * -10.0

	current_focus_point = target_focus_point

	# Establish baseline orientation and distance relative to target center
	var offset := global_position - current_focus_point
	target_distance = max(offset.length(), min_distance)
	current_distance = target_distance

	if not offset.is_zero_approx():
		target_orientation = Transform3D.IDENTITY.looking_at(offset, Vector3.UP).basis.get_rotation_quaternion()
	current_orientation = target_orientation

	initialize_input()
	LimboConsole.register_command(_toggle_gui, "debug_camera", "toggle camera debug on and off")

func _process(delta: float) -> void:
	target_focus_point = target_node.global_position + target_offset

	# Smoothly slerp quaternions and lerp position/distance
	var weight := delta * smoothing_speed
	current_orientation = current_orientation.slerp(target_orientation, weight).normalized()
	current_distance = lerpf(current_distance, target_distance, weight)
	current_focus_point = current_focus_point.lerp(target_focus_point, weight)

	# Calculate relative transform avoiding polar singular points
	var rot_basis := Basis(current_orientation)
	var offset := rot_basis * Vector3(0.0, 0.0, current_distance)

	global_transform = Transform3D(rot_basis, current_focus_point + offset)

	camera_moved.emit(self, get_viewport().get_visible_rect())

func initialize_input() -> void:
	G_InputWrapper.on_press("mouse_pressed", set_orbit_down)
	G_InputWrapper.on_release("mouse_pressed", set_orbit_up)
	
	G_InputWrapper.on_press("zoom_in", zoom_in)
	G_InputWrapper.on_press("zoom_out", zoom_out)
	G_InputWrapper.on_press("escape", close_application)
	G_InputWrapper.on_mouse_move(move_mouse)

func close_application(_name) -> void:
	get_tree().quit(0)

## Rotates camera to face a 3D surface point relative to the planet center and zooms in
func focus_on_surface_point(surface_point: Vector3, focus_distance: float = 6.0) -> void:
	var center := current_focus_point
	var dir_from_center := (surface_point - center).normalized()
	
	if dir_from_center.is_zero_approx():
		return

	# Calculate rotation quaternion where camera offset direction matches vector from planet center
	var look_transform := Transform3D.IDENTITY.looking_at(-dir_from_center, Vector3.UP)
	target_orientation = look_transform.basis.get_rotation_quaternion()
	target_distance = clampf(focus_distance, min_distance, max_distance)

#region Handle Input from House

## Mouse has moved, update orbiting
func move_mouse(_frame_distance: float, frame_delta: Vector2) -> void:
	if is_orbiting:
		
		# Pitch around current camera right axis, Yaw around planet global UP axis
		var yaw_quat := Quaternion(global_transform.basis.y, -frame_delta.x * orbit_sensitivity)
		var pitch_quat := Quaternion(global_transform.basis.x, -frame_delta.y * orbit_sensitivity)
		
		target_orientation = (pitch_quat * yaw_quat * target_orientation).normalized()

## Handle presses
func set_orbit_down(_name) -> void: 
	is_orbiting = true
	
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var ray_origin: Vector3 = project_ray_origin(mouse_pos)
	var ray_dir: Vector3 = project_ray_normal(mouse_pos)

	# Calculate explicit target point (from + direction * distance)
	var ray_end: Vector3 = ray_origin + (ray_dir * 10000.0)

	var space_state := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_end, 2)
	var result := space_state.intersect_ray(query)
	
	if not new_debug_line:
		new_debug_line = debug_line.instantiate()
		get_tree().root.add_child(new_debug_line)
	
	new_debug_line.draw_line_3d(ray_origin, ray_end)
	
	if not result.is_empty():
		var hit_node: Node = result.collider
		
		# Traverse up hierarchy to find GlobeWaypoint if collider is nested
		while hit_node and not (hit_node is GlobeWaypoint):
			hit_node = hit_node.get_parent()
		if hit_node is GlobeWaypoint:
			hit_node.on_clicked()

## Handle release
func set_orbit_up(_name) -> void: is_orbiting = false

func zoom_in(_name) -> void:
	target_distance = clampf(target_distance - zoom_sensitivity, min_distance, max_distance)

func zoom_out(_name) -> void:
	target_distance = clampf(target_distance + zoom_sensitivity, min_distance, max_distance)

#endregion

#region Debugging
func _toggle_gui() -> void:
	display_debug = !display_debug
	if display_debug:
		ImGui.imgui_layout.connect(_on_layout)
	elif ImGui.imgui_layout.is_connected(_on_layout):
		ImGui.imgui_layout.disconnect(_on_layout)

## Display this debug menu and value
func _on_layout() -> void:
	ImGui.set_next_window_size(0, 0, ImGui.COND_ALWAYS)
	ImGui.begin("Planet Orbit Camera Debug")

	if ImGui.collapsing_header("Camera State"):
		ImGui.indent(20)
		var format_3 := "(%.3f, %.3f, %.3f, %.3f)" % [current_orientation.x, current_orientation.y, current_orientation.y, current_orientation.z]
		ImGui.text("Focus Point: " + str(current_focus_point))
		ImGui.text("Distance: " + str(snappedf(current_distance, 0.01)))
		ImGui.text("Orientation (Quat): " + format_3)
		ImGui.unindent(20)

	if ImGui.collapsing_header("Controls"):
		ImGui.indent(20)
		orbit_sensitivity = ImGui.slider_float("Orbit Sensitivity", orbit_sensitivity, 0.001, 0.02)
		zoom_sensitivity = ImGui.slider_float("Zoom Speed", zoom_sensitivity, 0.5, 10.0)
		smoothing_speed = ImGui.slider_float("Smoothing Speed", smoothing_speed, 1.0, 30.0)
		ImGui.unindent(20)

	ImGui.end()
#endregion
