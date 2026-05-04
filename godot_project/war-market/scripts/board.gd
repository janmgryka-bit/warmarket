extends Node3D

@export var width: int = 8
@export var height: int = 8
@export var tile_size: float = 1.2

func _ready() -> void:
	print("BOARD SCRIPT DZIALA")
	create_board()

func create_board() -> void:
	var tile_count := 0
	
	for x in range(width):
		for z in range(height):
			var tile := MeshInstance3D.new()
			var mesh := BoxMesh.new()
			
			# Grube kafelki, żeby było je dobrze widać
			mesh.size = Vector3(tile_size * 0.9, 0.25, tile_size * 0.9)
			tile.mesh = mesh
			
			var material := StandardMaterial3D.new()
			material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			
			if (x + z) % 2 == 0:
				material.albedo_color = Color(0.85, 0.72, 0.45) # jasny piaskowy
			else:
				material.albedo_color = Color(0.30, 0.22, 0.14) # ciemny brąz
			
			tile.material_override = material
			tile.position = grid_to_world(Vector2i(x, z))
			tile.name = "Tile_%s_%s" % [x, z]
			
			add_child(tile)
			tile_count += 1
	
	print("UTWORZONO KAFELKOW: ", tile_count)

func grid_to_world(grid_pos: Vector2i) -> Vector3:
	var offset_x := (grid_pos.x - width / 2.0 + 0.5) * tile_size
	var offset_z := (grid_pos.y - height / 2.0 + 0.5) * tile_size
	
	# Wysoko nad areną, zero zlewania
	return Vector3(offset_x, 0.6, offset_z)

func get_spawn_position(grid_pos: Vector2i) -> Vector3:
	var pos := grid_to_world(grid_pos)
	pos.y = 1.0
	return pos
