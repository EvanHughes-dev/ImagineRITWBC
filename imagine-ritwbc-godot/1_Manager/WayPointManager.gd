extends Node3D

@export var camera: Camera3D
@export var planet_body: CollisionObject3D
@export var waypoint_scene: PackedScene

@export_flags_3d_physics var planet_layer: int = 1
@export_flags_3d_physics var waypoint_layer: int = 2

@export var default_zoom_distance: float = 6.0


func _ready() -> void:
	G_InputWrapper.on_press("right_mouse_pressed", _handle_click)

## Handle creating a new waypoint
func _handle_click(_name) -> void:
	var screen_pos := get_viewport().get_mouse_position()

	var ray_origin := camera.project_ray_origin(screen_pos)
	var ray_dir := camera.project_ray_normal(screen_pos)
	var space_state := camera.get_world_3d().direct_space_state

	# 1. Check if an existing Waypoint was clicked
	var waypoint_query := PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + ray_dir * 1000.0, waypoint_layer)
	var waypoint_result := space_state.intersect_ray(waypoint_query)

	if waypoint_result != {}:
		var hit_collider := waypoint_result.collider as Node
		var waypoint := _find_waypoint_parent(hit_collider)
		if waypoint:
			_select_waypoint(waypoint)
			return

	# 2. If no waypoint hit, check if planet surface was clicked to place a new one
	var planet_query := PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + ray_dir * 1000.0, planet_layer)
	var planet_result := space_state.intersect_ray(planet_query)

	if planet_result != {}:
		var hit_point: Vector3 = planet_result.position
		var hit_normal: Vector3 = planet_result.normal
		spawn_waypoint(hit_point, hit_normal)

## Spawn a new waypoint as a new position on the map
func spawn_waypoint(pos: Vector3, normal: Vector3) -> GlobeWaypoint:
	if not waypoint_scene:
		return null

	var waypoint_instance := waypoint_scene.instantiate() as GlobeWaypoint
	planet_body.add_child(waypoint_instance)
	
	waypoint_instance.global_position = pos
	
	# Align waypoint Y-axis with planet surface normal
	if not normal.is_equal_approx(Vector3.UP):
		var left := normal.cross(Vector3.UP).normalized()
		var forward := left.cross(normal).normalized()
		waypoint_instance.global_transform.basis = Basis(left, normal, forward)

	waypoint_instance.clicked.connect(_select_waypoint)
	return waypoint_instance

## Select a waypoint
func _select_waypoint(waypoint: GlobeWaypoint) -> void:
	if camera and camera.has_method("focus_on_surface_point"):
		camera.focus_on_surface_point(waypoint.global_position, waypoint.focus_zoom_distance)


func _find_waypoint_parent(node: Node) -> GlobeWaypoint:
	while node and node != get_tree().root:
		if node is GlobeWaypoint:
			return node
		node = node.get_parent()
	return null
