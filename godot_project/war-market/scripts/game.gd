extends Node3D

@onready var board: Node3D = $Board
@onready var units_container: Node3D = $Units
@onready var start_button: Button = $UI/StartBattleButton
@onready var restart_button: Button = $UI/RestartRoundButton
@onready var round_result_label: Label = $UI/RoundResultLabel

var unit_scene: PackedScene = preload("res://units/Unit.tscn")
var battle_started: bool = false
var round_ended: bool = false

func _ready() -> void:
	print("GAME READY")
	
	if start_button == null:
		print("ERROR: StartBattleButton not found")
	else:
		print("StartBattleButton found")
	
	if restart_button == null:
		print("ERROR: RestartRoundButton not found")
	else:
		print("RestartRoundButton found")
	
	board.tile_clicked.connect(_on_board_tile_clicked)
	
	round_result_label.text = ""
	restart_button.visible = false
	
	spawn_test_units()

func _process(_delta: float) -> void:
	if battle_started and not round_ended:
		check_round_end()

func spawn_test_units() -> void:
	spawn_unit("Legionista", 0, 140, 12, 1.0, 2.0, Vector2i(2, 6))
	spawn_unit("Berserker", 1, 110, 18, 1.1, 2.3, Vector2i(5, 1))

func spawn_unit(
	unit_name: String,
	team_id: int,
	max_hp: float,
	damage: float,
	attack_cooldown: float,
	move_speed: float,
	grid_pos: Vector2i
) -> CharacterBody3D:
	var unit = unit_scene.instantiate()
	unit.name = unit_name
	unit.unit_name = unit_name
	unit.team_id = team_id
	unit.max_hp = max_hp
	unit.damage = damage
	unit.attack_cooldown = attack_cooldown
	unit.move_speed = move_speed
	
	units_container.add_child(unit)
	place_unit_on_grid(unit, grid_pos)
	
	return unit

func place_unit_on_grid(unit: CharacterBody3D, grid_pos: Vector2i) -> void:
	unit.grid_position = grid_pos
	unit.global_position = board.get_spawn_position(grid_pos)
	print(unit.unit_name, " placed at: ", grid_pos)

func is_tile_occupied(grid_pos: Vector2i) -> bool:
	var units := get_tree().get_nodes_in_group("units")
	
	for unit in units:
		if not is_instance_valid(unit):
			continue
		
		if unit.current_hp <= 0:
			continue
		
		if unit.grid_position == grid_pos:
			return true
	
	return false

func _on_board_tile_clicked(grid_pos: Vector2i) -> void:
	if battle_started:
		print("Cannot move unit during battle")
		return
	
	if round_ended:
		print("Cannot move unit after round ended")
		return
	
	if grid_pos.y < 4:
		print("Enemy half - cannot place there")
		return
	
	if is_tile_occupied(grid_pos):
		print("Tile occupied: ", grid_pos)
		return
	
	var player_unit := get_first_player_unit()
	if player_unit == null:
		print("No player unit found")
		return
	
	place_unit_on_grid(player_unit, grid_pos)
	print("Moved player unit to: ", grid_pos)

func get_first_player_unit() -> CharacterBody3D:
	var units := get_tree().get_nodes_in_group("units")
	
	for unit in units:
		if unit.team_id == 0 and unit.current_hp > 0:
			return unit
	
	return null

func _on_start_battle_button_pressed() -> void:
	print("BUTTON CLICKED")
	start_battle()

func _on_restart_round_button_pressed() -> void:
	print("RESTART CLICKED")
	restart_round()

func start_battle() -> void:
	if battle_started:
		return
	
	battle_started = true
	round_ended = false
	round_result_label.text = ""
	restart_button.visible = false
	
	print("BATTLE STARTED")
	
	var units := get_tree().get_nodes_in_group("units")
	for unit in units:
		unit.start_battle()

func check_round_end() -> void:
	var blue_alive := false
	var red_alive := false
	
	var units := get_tree().get_nodes_in_group("units")
	
	for unit in units:
		if not is_instance_valid(unit):
			continue
		
		if unit.current_hp <= 0:
			continue
		
		if unit.team_id == 0:
			blue_alive = true
		elif unit.team_id == 1:
			red_alive = true
	
	if blue_alive and red_alive:
		return
	
	if not blue_alive and red_alive:
		end_round("RED WINS")
	elif blue_alive and not red_alive:
		end_round("BLUE WINS")
	else:
		end_round("DRAW")

func end_round(result_text: String) -> void:
	round_ended = true
	battle_started = false
	
	print("ROUND ENDED: ", result_text)
	round_result_label.text = result_text
	restart_button.visible = true
	
	var units := get_tree().get_nodes_in_group("units")
	for unit in units:
		if is_instance_valid(unit):
			unit.stop_battle()

func restart_round() -> void:
	clear_units()
	
	battle_started = false
	round_ended = false
	round_result_label.text = ""
	restart_button.visible = false
	
	spawn_test_units()

func clear_units() -> void:
	for child in units_container.get_children():
		child.queue_free()
