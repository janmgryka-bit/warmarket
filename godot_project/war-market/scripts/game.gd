extends Node3D

@onready var board: Node3D = $Board
@onready var units_container: Node3D = $Units
@onready var start_button: Button = $UI/StartBattleButton
@onready var restart_button: Button = $UI/RestartRoundButton
@onready var round_result_label: Label = $UI/RoundResultLabel
@onready var shop_items: HBoxContainer = $UI/ShopPanel/ShopItems

var unit_scene: PackedScene = preload("res://units/Unit.tscn")
var unit_database = preload("res://scripts/unit_database.gd")
var battle_started: bool = false
var round_ended: bool = false
var selected_unit: CharacterBody3D = null
var selected_shop_unit_id: String = ""
var shop_unit_ids: Array[String] = [
	"roman_legionary",
	"roman_archer",
	"viking_berserker"
]

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
	populate_shop()

func _process(_delta: float) -> void:
	if battle_started and not round_ended:
		check_round_end()

func spawn_test_units() -> void:
	spawn_unit_by_id("roman_legionary", 0, Vector2i(2, 6))
	spawn_unit_by_id("roman_archer", 0, Vector2i(4, 7))
	spawn_unit_by_id("viking_berserker", 1, Vector2i(5, 1))
	
func spawn_unit_by_id(unit_id: String, team_id: int, grid_pos: Vector2i) -> CharacterBody3D:
	var data: Dictionary = unit_database.get_unit_data(unit_id)
	
	if data.is_empty():
		return null
	
	var unit = unit_scene.instantiate()
	unit.name = unit_id
	unit.unit_name = data["name"]
	unit.team_id = team_id
	unit.role = data["role"]
	unit.max_hp = data["max_hp"]
	unit.damage = data["damage"]
	unit.attack_cooldown = data["attack_cooldown"]
	unit.move_speed = data["move_speed"]
	unit.attack_range = data["attack_range"]
	
	units_container.add_child(unit)
	unit.unit_clicked.connect(_on_unit_clicked)
	place_unit_on_grid(unit, grid_pos)
	
	print("Spawned unit: ", data["name"], " / faction: ", data["faction"])
	
	return unit

func _on_unit_clicked(unit: CharacterBody3D) -> void:
	if battle_started:
		print("Cannot select unit during battle")
		return
	
	if round_ended:
		print("Cannot select unit after round ended")
		return
	
	if unit.team_id != 0:
		print("Cannot select enemy unit")
		return
	
	select_unit(unit)

func select_unit(unit: CharacterBody3D) -> void:
	if selected_unit != null and is_instance_valid(selected_unit):
		selected_unit.set_selected(false)
	
	selected_unit = unit
	selected_unit.set_selected(true)
	print("SELECTED UNIT: ", selected_unit.unit_name)

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
	
	if selected_shop_unit_id != "":
		spawn_unit_by_id(selected_shop_unit_id, 0, grid_pos)
		print("Bought and placed unit: ", selected_shop_unit_id, " at ", grid_pos)
		selected_shop_unit_id = ""
		return

	if selected_unit == null or not is_instance_valid(selected_unit):
		print("No selected unit")
		return

	place_unit_on_grid(selected_unit, grid_pos)
	print("Moved selected unit to: ", grid_pos)

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
	
	if selected_unit != null and is_instance_valid(selected_unit):
		selected_unit.set_selected(false)
	selected_unit = null
	
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
	selected_unit = null
	
	spawn_test_units()

func clear_units() -> void:
	for child in units_container.get_children():
		child.queue_free()

func populate_shop() -> void:
	clear_shop()
	
	for unit_id in shop_unit_ids:
		var data: Dictionary = unit_database.get_unit_data(unit_id)
		
		if data.is_empty():
			continue
		
		var card := Button.new()
		card.custom_minimum_size = Vector2(220, 90)
		card.text = "%s\n%s\n%d gold" % [
			data["name"],
			data["role"],
			data["base_price"]
		]
		
		card.pressed.connect(_on_shop_card_pressed.bind(unit_id))
		shop_items.add_child(card)

func clear_shop() -> void:
	for child in shop_items.get_children():
		child.queue_free()

func _on_shop_card_pressed(unit_id: String) -> void:
	if battle_started:
		print("Cannot buy during battle")
		return
	
	if round_ended:
		print("Cannot buy after round ended")
		return
	
	var data: Dictionary = unit_database.get_unit_data(unit_id)
	
	if data.is_empty():
		return
	
	selected_shop_unit_id = unit_id
	
	if selected_unit != null and is_instance_valid(selected_unit):
		selected_unit.set_selected(false)
	selected_unit = null
	
	print("SELECTED SHOP UNIT: ", data["name"], " / price: ", data["base_price"])
