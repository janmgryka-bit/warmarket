extends Node3D

signal tile_clicked(grid_pos: Vector2i)

@export var width: int = 8
@export var height: int = 8
@export var tile_size: float = 1.2

var tile_bodies: Dictionary = {}
var tile_original_colors: Dictionary = {}
var highlighted_tile_positions: Array[Vector2i] = []
var highlight_color: Color = Color(0.25, 1.0, 0.35)
var stone_light_color: Color = Color(0.50, 0.51, 0.48)
var stone_dark_color: Color = Color(0.36, 0.37, 0.35)
var player_side_tint: Color = Color(0.20, 0.35, 0.50)
var enemy_side_tint: Color = Color(0.46, 0.25, 0.21)
var slab_edge_color: Color = Color(0.19, 0.20, 0.19)
var grout_color: Color = Color(0.12, 0.13, 0.12)
var crack_color: Color = Color(0.16, 0.17, 0.16)
var center_divider_color: Color = Color(0.58, 0.48, 0.27)
var player_side_marker_color: Color = Color(0.25, 0.45, 0.62)
var enemy_side_marker_color: Color = Color(0.60, 0.27, 0.22)
var platform_base_color: Color = Color(0.23, 0.24, 0.23)
var platform_side_color: Color = Color(0.16, 0.17, 0.16)
var frame_stone_color: Color = Color(0.29, 0.30, 0.28)
var frame_trim_color: Color = Color(0.50, 0.42, 0.25)
var reserve_dock_color: Color = Color(0.18, 0.16, 0.12)
var reserve_slot_color: Color = Color(0.26, 0.24, 0.19)
var reserve_slot_trim_color: Color = Color(0.54, 0.44, 0.25)

func _ready() -> void:
	print("BOARD SCRIPT DZIALA")
	create_board()

func create_board() -> void:
	var tile_count := 0

	create_arena_platform()
	
	for x in range(width):
		for z in range(height):
			var grid_pos := Vector2i(x, z)
			
			var tile_body := StaticBody3D.new()
			tile_body.name = "Tile_%s_%s" % [x, z]
			tile_body.position = grid_to_world(grid_pos)
			tile_body.set_meta("grid_pos", grid_pos)
			tile_body.input_ray_pickable = true
			add_child(tile_body)
			
			var edge_instance := create_tile_edge()
			tile_body.add_child(edge_instance)

			var mesh_instance := create_tile_slab(grid_pos)
			var material := mesh_instance.material_override as StandardMaterial3D
			mesh_instance.material_override = material
			tile_body.add_child(mesh_instance)

			var side_marker := create_side_marker(grid_pos)
			tile_body.add_child(side_marker)

			var crack_marker := create_crack_marker(grid_pos)
			if crack_marker != null:
				tile_body.add_child(crack_marker)

			var divider_marker := create_center_divider_marker(grid_pos)
			if divider_marker != null:
				tile_body.add_child(divider_marker)

			tile_bodies[grid_pos] = tile_body
			tile_original_colors[grid_pos] = material.albedo_color
			
			var collision := CollisionShape3D.new()
			var shape := BoxShape3D.new()
			shape.size = Vector3(tile_size * 0.9, 0.25, tile_size * 0.9)
			collision.shape = shape
			tile_body.add_child(collision)
			
			tile_body.input_event.connect(_on_tile_input_event.bind(tile_body))
			
			tile_count += 1
	
	print("UTWORZONO KAFELKOW: ", tile_count)

func create_arena_platform() -> void:
	var platform := Node3D.new()
	platform.name = "ArenaPlatform"
	add_child(platform)

	var board_width := width * tile_size
	var board_height := height * tile_size
	var platform_margin := tile_size * 0.42
	var platform_width := board_width + platform_margin * 2.0
	var platform_height := board_height + platform_margin * 2.0

	var base := create_platform_block(
		"ArenaStoneBase",
		Vector3(platform_width, 0.42, platform_height),
		Vector3(0.0, 0.30, 0.0),
		platform_base_color
	)
	platform.add_child(base)

	var shadow_side := create_platform_block(
		"ArenaLowerStone",
		Vector3(platform_width + 0.18, 0.30, platform_height + 0.18),
		Vector3(0.0, 0.10, 0.0),
		platform_side_color
	)
	platform.add_child(shadow_side)

	var frame_thickness := tile_size * 0.30
	var frame_height := 0.32
	var frame_y := 0.70
	var frame_z := board_height / 2.0 + frame_thickness / 2.0
	var frame_x := board_width / 2.0 + frame_thickness / 2.0

	platform.add_child(create_platform_block(
		"NorthStoneFrame",
		Vector3(platform_width, frame_height, frame_thickness),
		Vector3(0.0, frame_y, -frame_z),
		frame_stone_color
	))
	platform.add_child(create_platform_block(
		"SouthStoneFrame",
		Vector3(platform_width, frame_height, frame_thickness),
		Vector3(0.0, frame_y, frame_z),
		frame_stone_color
	))
	platform.add_child(create_platform_block(
		"WestStoneFrame",
		Vector3(frame_thickness, frame_height, board_height),
		Vector3(-frame_x, frame_y, 0.0),
		frame_stone_color
	))
	platform.add_child(create_platform_block(
		"EastStoneFrame",
		Vector3(frame_thickness, frame_height, board_height),
		Vector3(frame_x, frame_y, 0.0),
		frame_stone_color
	))

	create_platform_corner_supports(platform, frame_x, frame_z)
	create_platform_trim(platform, platform_width, platform_height)
	create_reserve_dock(platform, board_width, frame_z)

func create_platform_block(block_name: String, block_size: Vector3, block_position: Vector3, color: Color) -> MeshInstance3D:
	var block := MeshInstance3D.new()
	block.name = block_name
	var mesh := BoxMesh.new()
	mesh.size = block_size
	block.mesh = mesh
	block.position = block_position
	block.material_override = create_stone_material(color)
	return block

func create_platform_corner_supports(platform: Node3D, frame_x: float, frame_z: float) -> void:
	var corner_positions: Array[Vector3] = [
		Vector3(-frame_x, 0.54, -frame_z),
		Vector3(frame_x, 0.54, -frame_z),
		Vector3(-frame_x, 0.54, frame_z),
		Vector3(frame_x, 0.54, frame_z),
	]
	for index in range(corner_positions.size()):
		var support := create_platform_block(
			"CornerSupport_%s" % index,
			Vector3(tile_size * 0.48, 0.72, tile_size * 0.48),
			corner_positions[index],
			frame_stone_color.darkened(0.08)
		)
		platform.add_child(support)

func create_platform_trim(platform: Node3D, platform_width: float, platform_height: float) -> void:
	var trim_height := 0.05
	var trim_width := 0.08
	var trim_y := 0.90
	var trim_z := platform_height / 2.0 - tile_size * 0.20
	var trim_x := platform_width / 2.0 - tile_size * 0.20

	platform.add_child(create_platform_block(
		"NorthMetalTrim",
		Vector3(platform_width - tile_size * 0.38, trim_height, trim_width),
		Vector3(0.0, trim_y, -trim_z),
		frame_trim_color
	))
	platform.add_child(create_platform_block(
		"SouthMetalTrim",
		Vector3(platform_width - tile_size * 0.38, trim_height, trim_width),
		Vector3(0.0, trim_y, trim_z),
		frame_trim_color
	))
	platform.add_child(create_platform_block(
		"WestMetalTrim",
		Vector3(trim_width, trim_height, platform_height - tile_size * 0.38),
		Vector3(-trim_x, trim_y, 0.0),
		frame_trim_color
	))
	platform.add_child(create_platform_block(
		"EastMetalTrim",
		Vector3(trim_width, trim_height, platform_height - tile_size * 0.38),
		Vector3(trim_x, trim_y, 0.0),
		frame_trim_color
	))

func create_reserve_dock(platform: Node3D, board_width: float, front_frame_z: float) -> void:
	var dock_depth := tile_size * 0.72
	var dock_width := board_width - tile_size * 0.22
	var dock_z := front_frame_z + dock_depth * 0.58
	var dock := create_platform_block(
		"ReserveDock",
		Vector3(dock_width, 0.18, dock_depth),
		Vector3(0.0, 0.76, dock_z),
		reserve_dock_color
	)
	platform.add_child(dock)

	var slot_count := 8
	var slot_gap := tile_size * 0.08
	var slot_width := (dock_width - slot_gap * float(slot_count + 1)) / float(slot_count)
	for index in range(slot_count):
		var slot_x := -dock_width / 2.0 + slot_gap + slot_width / 2.0 + float(index) * (slot_width + slot_gap)
		var slot := create_platform_block(
			"ReserveSlot_%s" % index,
			Vector3(slot_width, 0.035, dock_depth * 0.56),
			Vector3(slot_x, 0.875, dock_z),
			reserve_slot_color
		)
		platform.add_child(slot)

	var front_trim := create_platform_block(
		"ReserveDockFrontTrim",
		Vector3(dock_width, 0.06, 0.08),
		Vector3(0.0, 0.91, dock_z + dock_depth * 0.44),
		reserve_slot_trim_color
	)
	platform.add_child(front_trim)

func create_tile_slab(grid_pos: Vector2i) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "StoneSlab"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(tile_size * 0.88, 0.18, tile_size * 0.88)
	mesh_instance.mesh = mesh
	mesh_instance.position = Vector3(0.0, 0.04, 0.0)
	mesh_instance.material_override = create_stone_material(get_tile_stone_color(grid_pos))
	return mesh_instance

func create_tile_edge() -> MeshInstance3D:
	var edge_instance := MeshInstance3D.new()
	edge_instance.name = "StoneGrout"
	var edge_mesh := BoxMesh.new()
	edge_mesh.size = Vector3(tile_size * 0.98, 0.16, tile_size * 0.98)
	edge_instance.mesh = edge_mesh
	edge_instance.position = Vector3(0.0, -0.04, 0.0)
	edge_instance.material_override = create_stone_material(grout_color)
	return edge_instance

func create_side_marker(grid_pos: Vector2i) -> MeshInstance3D:
	var marker := MeshInstance3D.new()
	marker.name = "SideMarker"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(tile_size * 0.54, 0.025, 0.045)
	marker.mesh = mesh
	var player_start_y := floori(float(height) / 2.0)
	var marker_z := tile_size * 0.34 if grid_pos.y >= player_start_y else -tile_size * 0.34
	marker.position = Vector3(0.0, 0.145, marker_z)
	var marker_color := player_side_marker_color if grid_pos.y >= player_start_y else enemy_side_marker_color
	marker.material_override = create_stone_material(marker_color.darkened(0.12))
	return marker

func create_crack_marker(grid_pos: Vector2i) -> MeshInstance3D:
	if (grid_pos.x * 3 + grid_pos.y * 5) % 4 == 0:
		var crack := MeshInstance3D.new()
		crack.name = "StoneCrack"
		var mesh := BoxMesh.new()
		var crack_length := tile_size * (0.26 + float((grid_pos.x + grid_pos.y) % 3) * 0.08)
		mesh.size = Vector3(crack_length, 0.018, 0.025)
		crack.mesh = mesh
		var offset_x := tile_size * (-0.12 + float(grid_pos.x % 3) * 0.08)
		var offset_z := tile_size * (-0.10 + float(grid_pos.y % 3) * 0.07)
		crack.position = Vector3(offset_x, 0.155, offset_z)
		crack.rotation.y = deg_to_rad(18.0 if (grid_pos.x + grid_pos.y) % 2 == 0 else -24.0)
		crack.material_override = create_stone_material(crack_color)
		return crack
	return null

func create_center_divider_marker(grid_pos: Vector2i) -> MeshInstance3D:
	var player_start_y := floori(float(height) / 2.0)
	if grid_pos.y != player_start_y - 1:
		return null
	var divider := MeshInstance3D.new()
	divider.name = "CenterDivider"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(tile_size * 0.72, 0.03, 0.055)
	divider.mesh = mesh
	divider.position = Vector3(0.0, 0.165, tile_size * 0.47)
	divider.material_override = create_stone_material(center_divider_color.darkened(0.08))
	return divider

func get_tile_stone_color(grid_pos: Vector2i) -> Color:
	var color := stone_light_color if (grid_pos.x + grid_pos.y) % 2 == 0 else stone_dark_color
	var variation := float((grid_pos.x * 11 + grid_pos.y * 7) % 5) * 0.015
	color = color.lightened(variation)
	var player_start_y := floori(float(height) / 2.0)
	if grid_pos.y >= player_start_y:
		return color.lerp(player_side_tint, 0.14)
	return color.lerp(enemy_side_tint, 0.13)

func create_stone_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.82
	material.metallic = 0.0
	return material

func _on_tile_input_event(
	_camera: Camera3D,
	event: InputEvent,
	_position: Vector3,
	_normal: Vector3,
	_shape_idx: int,
	tile_body: StaticBody3D
) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var grid_pos: Vector2i = tile_body.get_meta("grid_pos")
			print("CLICKED TILE: ", grid_pos)
			tile_clicked.emit(grid_pos)

func grid_to_world(grid_pos: Vector2i) -> Vector3:
	var offset_x := (grid_pos.x - width / 2.0 + 0.5) * tile_size
	var offset_z := (grid_pos.y - height / 2.0 + 0.5) * tile_size
	
	return Vector3(offset_x, 0.6, offset_z)

func get_spawn_position(grid_pos: Vector2i) -> Vector3:
	var pos := grid_to_world(grid_pos)
	pos.y = 1.0
	return pos

func clear_tile_highlights() -> void:
	for grid_pos in highlighted_tile_positions:
		if not tile_bodies.has(grid_pos):
			continue
		var mesh_instance := get_tile_mesh_instance(tile_bodies[grid_pos])
		if mesh_instance == null:
			continue
		if mesh_instance.material_override is StandardMaterial3D:
			var material := mesh_instance.material_override as StandardMaterial3D
			material.albedo_color = tile_original_colors.get(grid_pos, material.albedo_color)
	highlighted_tile_positions.clear()

func highlight_tiles(tile_positions: Array[Vector2i]) -> void:
	clear_tile_highlights()
	for grid_pos in tile_positions:
		if not tile_bodies.has(grid_pos):
			continue
		var mesh_instance := get_tile_mesh_instance(tile_bodies[grid_pos])
		if mesh_instance == null:
			continue
		if mesh_instance.material_override is StandardMaterial3D:
			var material := mesh_instance.material_override as StandardMaterial3D
			material.albedo_color = highlight_color
			highlighted_tile_positions.append(grid_pos)

func get_tile_mesh_instance(tile_body: Node) -> MeshInstance3D:
	for child in tile_body.get_children():
		if child is MeshInstance3D and child.name == "StoneSlab":
			return child
	return null
