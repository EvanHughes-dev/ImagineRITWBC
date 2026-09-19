extends MeshInstance3D

func draw_line_3d(from: Vector3, to: Vector3, color: Color = Color.RED) -> void:
	var imm_mesh := ImmediateMesh.new()
	mesh = imm_mesh
	
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color

	imm_mesh.clear_surfaces()
	imm_mesh.surface_begin(Mesh.PRIMITIVE_LINES, mat)
	imm_mesh.surface_add_vertex(from)
	imm_mesh.surface_add_vertex(to)
	imm_mesh.surface_end()
