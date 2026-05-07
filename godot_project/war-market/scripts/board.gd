extends Node3D

signal tile_clicked(grid_pos: Vector2i)

@export var width: int = 8
@export var height: int = 8
@export var tile_size: float = 1.2

var tile_bodies: Dictionary = {}
var tile_original_colors: Dictionary = {}
var highlighted_tile_positions: Array[Vector2i] = []
var highlight_color: Color = Color(0.25, 1.0, 0.35)
var stone_light_color: Color = Color(0.48, 0.49, 0.47)
var stone_dark_color: Color = Color(0.36, 0.37, 0.36)
var player_side_tint: Color = Color(0.18, 0.34, 0.52)
var enemy_side_tint: Color = Color(0.48, 0.24, 0.22)
var slab_edge_color: Color = Color(0.20, 0.21, 0.20)

func _ready() -> void:
	print("BOARD SCRIPT DZIALA")
	create_board()

func create_board() -> void:
	var tile_count := 0
	
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
	edge_instance.name = "SlabEdge"
	var edge_mesh := BoxMesh.new()
	edge_mesh.size = Vector3(tile_size * 0.96, 0.16, tile_size * 0.96)
	edge_instance.mesh = edge_mesh
	edge_instance.position = Vector3(0.0, -0.04, 0.0)
	edge_instance.material_override = create_stone_material(slab_edge_color)
	return edge_instance

func get_tile_stone_color(grid_pos: Vector2i) -> Color:
	var color := stone_light_color if (grid_pos.x + grid_pos.y) % 2 == 0 else stone_dark_color
	if grid_pos.y >= height / 2:
		return color.lerp(player_side_tint, 0.18)
	return color.lerp(enemy_side_tint, 0.16)

func create_stone_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.82
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
