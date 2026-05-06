extends Node3D

# References
@onready var board: Node3D = $Board
@onready var units_container: Node3D = $Units
@onready var start_button: Button = $UI/StartBattleButton
@onready var restart_button: Button = $UI/RestartRoundButton
@onready var round_result_label: Label = $UI/RoundResultLabel
@onready var shop_items: HBoxContainer = $UI/ShopPanel/ShopItems
@onready var gold_label: Label = $UI/GoldLabel
@onready var round_label: Label = $UI/RoundLabel
@onready var reroll_button: Button = $UI/RerollButton
@onready var sell_unit_button: Button = $UI/SellUnitButton
@onready var unit_cap_label: Label = $UI/UnitCapLabel

# Resources
var unit_scene: PackedScene = preload("res://units/Unit.tscn")
var unit_database = preload("res://scripts/unit_database.gd")

# State
var battle_started: bool = false
var round_ended: bool = false
var selected_unit: CharacterBody3D = null
var selected_shop_unit_id: String = ""

# Selection Helpers
func clear_shop_selection() -> void:
	selected_shop_unit_id = ""

func clear_unit_selection() -> void:
	if selected_unit != null and is_instance_valid(selected_unit):
		selected_unit.set_selected(false)
	selected_unit = null

func clear_all_selection() -> void:
	clear_shop_selection()
	clear_unit_selection()

# Economy
var starting_gold: int = 10
var round_income: int = 5
var reroll_cost: int = 2
var max_player_units: int = 5
var player_gold: int = starting_gold
var shop_unit_ids: Array[String] = [
	"roman_legionary",
	"roman_archer",
	"viking_berserker",
	"roman_spearman",
	"viking_axeman",
	"slav_hunter"
]
var shop_offer_count: int = 3
var current_shop_offers: Array[String] = []
var player_roster: Array[Dictionary] = []
var roster_id_counter: int = 0
var round_number: int = 1

# Setup
func _ready() -> void:
	print("GAME READY")
	
	randomize()
	
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
	
	update_gold_label()
	spawn_test_units()
	roll_shop_offers()
	populate_shop()
	update_unit_cap_label()
	round_label.text = "Round: %d" % round_number

# Frame Updates
func _process(_delta: float) -> void:
	if battle_started and not round_ended:
		check_round_end()

# Spawning
func spawn_test_units() -> void:
	add_player_roster_unit("roman_legionary", Vector2i(2, 6))
	add_player_roster_unit("roman_archer", Vector2i(4, 7))
	spawn_player_roster()
	spawn_enemy_wave(1)

func add_player_roster_unit(unit_id: String, grid_pos: Vector2i) -> void:
	roster_id_counter += 1
	player_roster.append({"roster_id": roster_id_counter, "unit_id": unit_id, "grid_pos": grid_pos})
	print("Added to roster: ", unit_id, " at ", grid_pos, " id: ", roster_id_counter)

func spawn_player_roster() -> void:
	for entry in player_roster:
		var unit = spawn_unit_by_id(entry["unit_id"], 0, entry["grid_pos"])
		if unit:
			unit.set_meta("roster_id", entry["roster_id"])
			print("Spawning roster unit: ", entry["unit_id"], " at ", entry["grid_pos"], " id: ", entry["roster_id"])

func spawn_enemy_test_units() -> void:
	spawn_unit_by_id("viking_berserker", 1, Vector2i(5, 1))

func spawn_enemy_wave(round_num: int) -> void:
	if round_num == 1:
		spawn_unit_by_id("viking_berserker", 1, Vector2i(5, 1))
	elif round_num == 2:
		spawn_unit_by_id("viking_berserker", 1, Vector2i(5, 1))
		spawn_unit_by_id("viking_berserker", 1, Vector2i(6, 1))
	else:
		spawn_unit_by_id("viking_berserker", 1, Vector2i(5, 1))
		spawn_unit_by_id("viking_berserker", 1, Vector2i(6, 1))
		spawn_unit_by_id("roman_archer", 1, Vector2i(4, 1))

func roll_shop_offers() -> void:
	current_shop_offers.clear()
	for i in range(shop_offer_count):
		var random_index = randi_range(0, shop_unit_ids.size() - 1)
		current_shop_offers.append(shop_unit_ids[random_index])

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

# Unit Selection and Movement
func _on_unit_clicked(unit: CharacterBody3D) -> void:
	if not is_preparation_phase():
		print("Cannot select unit outside preparation phase")
		return
	
	if unit.team_id != 0:
		print("Cannot select enemy unit")
		return
	
	clear_shop_selection()
	
	# Toggle selection: if already selected, deselect
	if selected_unit != null and is_instance_valid(selected_unit) and selected_unit == unit:
		clear_unit_selection()
		print("DESELECTED UNIT")
		return
	
	# Otherwise select the new unit
	clear_unit_selection()
	select_unit(unit)

func select_unit(unit: CharacterBody3D) -> void:
	selected_unit = unit
	selected_unit.set_selected(true)
	print("SELECTED UNIT: ", selected_unit.unit_name)

func place_unit_on_grid(unit: CharacterBody3D, grid_pos: Vector2i) -> void:
	unit.grid_position = grid_pos
	unit.global_position = board.get_spawn_position(grid_pos)
	print(unit.unit_name, " placed at: ", grid_pos)
	update_player_roster_position(unit, grid_pos)

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

# Board Interaction
func _on_board_tile_clicked(grid_pos: Vector2i) -> void:
	if not is_preparation_phase():
		print("Cannot interact with board outside preparation phase")
		return
	
	if grid_pos.y < 4:
		print("Enemy half - cannot place there")
		return
	
	if is_tile_occupied(grid_pos):
		print("Tile occupied: ", grid_pos)
		return
	
	if selected_shop_unit_id != "":
		var data: Dictionary = unit_database.get_unit_data(selected_shop_unit_id)
		var cost = data["base_price"]
		
		if player_roster.size() >= max_player_units:
			print("Unit cap reached")
			clear_shop_selection()
			return
		
		if player_gold >= cost:
			var unit = spawn_unit_by_id(selected_shop_unit_id, 0, grid_pos)
			add_player_roster_unit(selected_shop_unit_id, grid_pos)
			if unit:
				unit.set_meta("roster_id", roster_id_counter)
				print("Set meta roster_id ", roster_id_counter, " on bought unit ", selected_shop_unit_id)
			player_gold -= cost
			update_gold_label()
			update_unit_cap_label()
			print("Bought and placed unit: ", selected_shop_unit_id, " at ", grid_pos, " for ", cost, " gold")
			populate_shop()
			clear_shop_selection()
		else:
			print("Cannot afford unit. Need ", cost, " gold, have ", player_gold)
			clear_shop_selection()
		return

	if selected_unit == null or not is_instance_valid(selected_unit):
		print("No selected unit")
		return

	place_unit_on_grid(selected_unit, grid_pos)
	print("Moved selected unit to: ", grid_pos)
	clear_unit_selection()

func get_first_player_unit() -> CharacterBody3D:
	var units := get_tree().get_nodes_in_group("units")
	
	for unit in units:
		if unit.team_id == 0 and unit.current_hp > 0:
			return unit
	
	return null

# Battle
func _on_start_battle_button_pressed() -> void:
	print("BUTTON CLICKED")
	start_battle()

func start_battle() -> void:
	if battle_started:
		return
	
	battle_started = true
	round_ended = false
	round_result_label.text = ""
	restart_button.visible = false
	
	clear_all_selection()
	
	print("BATTLE STARTED")
	
	var units := get_tree().get_nodes_in_group("units")
	for unit in units:
		unit.start_battle()

func is_preparation_phase() -> bool:
	return not battle_started and not round_ended

func check_round_end() -> void:
	var player_alive := false
	var enemy_alive := false
	
	var units := get_tree().get_nodes_in_group("units")
	
	for unit in units:
		if not is_instance_valid(unit):
			continue
		
		if unit.current_hp <= 0:
			continue
		
		if unit.team_id == 0:
			player_alive = true
		elif unit.team_id == 1:
			enemy_alive = true
	
	if player_alive and enemy_alive:
		return
	
	if not player_alive and enemy_alive:
		end_round("ENEMY WINS")
	elif player_alive and not enemy_alive:
		end_round("PLAYER WINS")
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

func _on_restart_round_button_pressed() -> void:
	print("RESTART CLICKED")
	restart_round()

func restart_round() -> void:
	clear_units()
	
	battle_started = false
	round_ended = false
	round_result_label.text = ""
	restart_button.visible = false
	clear_all_selection()
	round_number += 1
	player_gold += round_income
	
	update_gold_label()
	round_label.text = "Round: %d" % round_number
	update_unit_cap_label()
	populate_shop()
	spawn_player_roster()
	spawn_enemy_wave(round_number)

func update_player_roster_position(unit: CharacterBody3D, new_grid_pos: Vector2i) -> void:
	if unit.team_id != 0:
		return
	
	if not unit.has_meta("roster_id"):
		return
	
	var roster_id = unit.get_meta("roster_id")
	for entry in player_roster:
		if entry["roster_id"] == roster_id:
			entry["grid_pos"] = new_grid_pos
			print("Updated roster position for id ", roster_id, " to ", new_grid_pos)
			return

func clear_units() -> void:
	for child in units_container.get_children():
		child.queue_free()

# Shop
func populate_shop() -> void:
	clear_shop()
	
	for unit_id in current_shop_offers:
		var data: Dictionary = unit_database.get_unit_data(unit_id)
		
		if data.is_empty():
			continue
		
		var card := Button.new()
		card.custom_minimum_size = Vector2(220, 90)
		var can_afford = player_gold >= data["base_price"]
		var affordability_text = "(Affordable)" if can_afford else "(Too Expensive)"
		card.text = "%s\n%s\n%d gold %s" % [
			data["name"],
			data["role"],
			data["base_price"],
			affordability_text
		]
		card.disabled = not can_afford
		
		card.pressed.connect(_on_shop_card_pressed.bind(unit_id))
		shop_items.add_child(card)

func clear_shop() -> void:
	for child in shop_items.get_children():
		child.queue_free()

func _on_shop_card_pressed(unit_id: String) -> void:
	if not is_preparation_phase():
		print("Cannot buy outside preparation phase")
		return
	
	var data: Dictionary = unit_database.get_unit_data(unit_id)
	
	if data.is_empty():
		return
	
	var cost = data["base_price"]
	if player_gold < cost:
		print("Cannot afford ", data["name"], ". Need ", cost, " gold, have ", player_gold)
		return
	
	clear_all_selection()
	selected_shop_unit_id = unit_id
	
	print("SELECTED SHOP UNIT: ", data["name"], " / price: ", cost)

func _on_reroll_button_pressed() -> void:
	if not is_preparation_phase():
		print("Cannot reroll outside preparation phase")
		return
	
	if player_gold < reroll_cost:
		print("Cannot afford reroll. Need ", reroll_cost, " gold, have ", player_gold)
		return
	
	clear_shop_selection()
	player_gold -= reroll_cost
	update_gold_label()
	roll_shop_offers()
	populate_shop()
	print("Rerolled shop for ", reroll_cost, " gold")

func _on_sell_unit_button_pressed() -> void:
	if not is_preparation_phase():
		print("Cannot sell outside preparation phase")
		return
	
	if selected_unit == null or not is_instance_valid(selected_unit):
		print("No unit selected to sell")
		return
	
	if selected_unit.team_id != 0:
		print("Cannot sell enemy unit")
		return
	
	if not selected_unit.has_meta("roster_id"):
		print("Selected unit has no roster_id")
		return
	
	var roster_id = selected_unit.get_meta("roster_id")
	var roster_entry = null
	var roster_index = -1
	
	for i in range(player_roster.size()):
		if player_roster[i]["roster_id"] == roster_id:
			roster_entry = player_roster[i]
			roster_index = i
			break
	
	if roster_entry == null:
		print("Roster entry not found for unit with roster_id ", roster_id)
		return
	
	var unit_id = roster_entry["unit_id"]
	var unit_data = unit_database.get_unit_data(unit_id)
	
	if unit_data.is_empty():
		print("Unit data not found for unit_id ", unit_id)
		return
	
	var refund = unit_data["base_price"]
	
	player_gold += refund
	player_roster.remove_at(roster_index)
	selected_unit.queue_free()
	clear_all_selection()
	
	update_gold_label()
	update_unit_cap_label()
	populate_shop()
	print("Sold ", unit_data["name"], " for ", refund, " gold")

# UI
func update_gold_label() -> void:
	gold_label.text = "Gold: %d" % player_gold

func update_unit_cap_label() -> void:
	unit_cap_label.text = "Units: %d / %d" % [player_roster.size(), max_player_units]
