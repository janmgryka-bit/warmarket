extends Node3D

# References
@onready var board: Node3D = $Board
@onready var units_container: Node3D = $Units
@onready var start_button: Button = $UI/HudContainer/StartBattleButton
@onready var battle_speed_button: Button = $UI/HudContainer/BattleSpeedButton
@onready var restart_button: Button = $UI/RestartRoundButton
@onready var round_result_label: Label = $UI/HudContainer/RoundResultLabel
@onready var unit_details_panel: Panel = $UI/UnitDetailsPanel
@onready var unit_details_label: Label = $UI/UnitDetailsPanel/UnitDetailsLabel
@onready var event_log_label: Label = $UI/EventLogPanel/EventLogLabel
@onready var shop_items: HBoxContainer = $UI/BottomContainer/ShopPanel/ShopItems
@onready var gold_label: Label = $UI/HudContainer/GoldLabel
@onready var player_level_label: Label = $UI/HudContainer/PlayerLevelLabel
@onready var round_label: Label = $UI/HudContainer/RoundLabel
@onready var reroll_button: Button = $UI/HudContainer/RerollButton
@onready var buy_xp_button: Button = $UI/HudContainer/BuyXPButton
@onready var sell_unit_button: Button = $UI/HudContainer/SellUnitButton
@onready var unit_cap_label: Label = $UI/HudContainer/UnitCapLabel
@onready var synergy_label: Label = $UI/HudContainer/SynergyLabel
@onready var player_health_label: Label = $UI/HudContainer/PlayerHealthLabel
@onready var bench_label: Label = $UI/BottomContainer/BenchPanel/BenchLabel
@onready var bench_items: HBoxContainer = $UI/BottomContainer/BenchPanel/BenchItems

# Resources
var unit_scene: PackedScene = preload("res://units/Unit.tscn")
var unit_database = preload("res://scripts/unit_database.gd")

# State
var battle_started: bool = false
var round_ended: bool = false
var selected_unit: CharacterBody3D = null
var selected_shop_unit_id: String = ""
var battle_speed_values: Array[float] = [1.0, 2.0, 4.0]
var battle_speed_index: int = 0
var event_log: Array[String] = []
var max_event_log_entries: int = 8

# Selection Helpers
func clear_shop_selection() -> void:
	selected_shop_unit_id = ""

func clear_unit_selection() -> void:
	if selected_unit != null and is_instance_valid(selected_unit):
		selected_unit.set_selected(false)
	selected_unit = null
	update_unit_details_panel()

func clear_bench_selection() -> void:
	selected_bench_index = -1

func clear_all_selection() -> void:
	clear_shop_selection()
	clear_unit_selection()
	clear_bench_selection()

# Economy
var starting_gold: int = 10
var round_income: int = 5
var reroll_cost: int = 2
var win_bonus_gold: int = 2
var draw_bonus_gold: int = 1
var player_level: int = 1
var player_xp: int = 0
var xp_per_purchase: int = 4
var xp_purchase_cost: int = 4
var max_player_level: int = 6
var max_player_units: int = 2
var player_gold: int = starting_gold
var starting_player_health: int = 20
var player_health: int = starting_player_health
var loss_damage: int = 4
var game_over: bool = false
var max_rounds: int = 10
var victory: bool = false
var shop_unit_ids: Array[String] = [
	"roman_legionary",
	"roman_archer",
	"viking_berserker",
	"roman_spearman",
	"viking_axeman",
	"slav_hunter",
	"roman_centurion",
	"viking_raider",
	"mongol_horse_archer"
]
var shop_tier_odds := {
	1: {1: 100},
	2: {1: 100},
	3: {1: 85, 2: 15},
	4: {1: 70, 2: 30},
	5: {1: 55, 2: 40, 3: 5},
	6: {1: 40, 2: 45, 3: 15}
}
var shop_offer_count: int = 3
var current_shop_offers: Array[String] = []
var sold_shop_offer_indices: Array[int] = []

# Enemy wave definitions by round
var enemy_wave_definitions: Dictionary = {
	1: [
		{"unit_id": "viking_berserker", "grid_pos": Vector2i(5, 1)}
	],
	2: [
		{"unit_id": "viking_berserker", "grid_pos": Vector2i(5, 1)},
		{"unit_id": "viking_axeman", "grid_pos": Vector2i(6, 1)}
	],
	3: [
		{"unit_id": "viking_berserker", "grid_pos": Vector2i(5, 1)},
		{"unit_id": "viking_axeman", "grid_pos": Vector2i(6, 1)},
		{"unit_id": "roman_archer", "grid_pos": Vector2i(4, 1)}
	],
	4: [
		{"unit_id": "viking_berserker", "grid_pos": Vector2i(5, 1)},
		{"unit_id": "viking_axeman", "grid_pos": Vector2i(6, 1)},
		{"unit_id": "roman_archer", "grid_pos": Vector2i(4, 1)},
		{"unit_id": "slav_hunter", "grid_pos": Vector2i(3, 1)}
	],
	5: [
		{"unit_id": "viking_berserker", "grid_pos": Vector2i(5, 1)},
		{"unit_id": "viking_axeman", "grid_pos": Vector2i(6, 1)},
		{"unit_id": "roman_archer", "grid_pos": Vector2i(4, 1)},
		{"unit_id": "slav_hunter", "grid_pos": Vector2i(3, 1)},
		{"unit_id": "roman_spearman", "grid_pos": Vector2i(2, 1)}
	]
}

var player_roster: Array[Dictionary] = []
var roster_id_counter: int = 0
var round_number: int = 1
var last_round_result: String = ""
var bench_units: Array[Dictionary] = []
var max_bench_units: int = 6
var selected_bench_index: int = -1

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
	apply_battle_speed()
	update_battle_speed_ui()
	add_event_log("Game ready")

	update_gold_label()
	update_player_health_label()
	update_max_player_units()
	update_player_level_label()
	spawn_test_units()
	roll_shop_offers()
	populate_shop()
	update_unit_cap_label()
	update_synergy_label()
	update_bench_ui()
	update_round_label()

# Frame Updates
func _process(_delta: float) -> void:
	if battle_started and not round_ended:
		check_round_end()

func _exit_tree() -> void:
	Engine.time_scale = 1.0

func add_event_log(message: String) -> void:
	event_log.append(message)
	while event_log.size() > max_event_log_entries:
		event_log.remove_at(0)
	update_event_log_ui()
	print(message)

func update_event_log_ui() -> void:
	if event_log_label == null:
		return
	if event_log.is_empty():
		event_log_label.text = "Event Log"
		return
	var lines := PackedStringArray()
	for entry in event_log:
		lines.append(entry)
	event_log_label.text = "Event Log\n" + "\n".join(lines)

func apply_battle_speed() -> void:
	Engine.time_scale = battle_speed_values[battle_speed_index]

func update_battle_speed_ui() -> void:
	battle_speed_button.text = "Speed: %dx" % int(battle_speed_values[battle_speed_index])

func reset_battle_speed() -> void:
	battle_speed_index = 0
	apply_battle_speed()
	update_battle_speed_ui()

func _on_battle_speed_button_pressed() -> void:
	battle_speed_index = (battle_speed_index + 1) % battle_speed_values.size()
	apply_battle_speed()
	update_battle_speed_ui()
	print("Battle speed set to ", battle_speed_values[battle_speed_index], "x")

# Spawning
func spawn_test_units() -> void:
	add_player_roster_unit("roman_legionary", Vector2i(2, 6))
	add_player_roster_unit("roman_archer", Vector2i(4, 7))
	spawn_player_roster()
	spawn_enemy_wave(1)

func add_player_roster_unit(unit_id: String, grid_pos: Vector2i, star_level: int = 1) -> void:
	roster_id_counter += 1
	player_roster.append({"roster_id": roster_id_counter, "unit_id": unit_id, "grid_pos": grid_pos, "star_level": star_level})
	print("Added to roster: ", unit_id, " at ", grid_pos, " id: ", roster_id_counter, " star: ", star_level)

func spawn_player_roster() -> void:
	for entry in player_roster:
		var star_level = entry.get("star_level", 1)
		var unit = spawn_unit_by_id(entry["unit_id"], 0, entry["grid_pos"], star_level)
		if unit:
			unit.set_meta("roster_id", entry["roster_id"])
			unit.set_meta("star_level", star_level)
			print("Spawning roster unit: ", entry["unit_id"], " at ", entry["grid_pos"], " id: ", entry["roster_id"], " star: ", star_level)
	refresh_player_unit_bonuses()

func spawn_enemy_test_units() -> void:
	spawn_unit_by_id("viking_berserker", 1, Vector2i(5, 1))

func spawn_enemy_wave(round_num: int) -> void:
	# Get wave definition for this round
	# Use exact definition if it exists, otherwise use the highest available
	var wave_def: Array = []
	
	if round_num in enemy_wave_definitions:
		wave_def = enemy_wave_definitions[round_num]
	else:
		# Use the highest available definition for rounds beyond defined ones
		var max_defined_round = 5
		if max_defined_round in enemy_wave_definitions:
			wave_def = enemy_wave_definitions[max_defined_round]
	
	# Spawn all units in the wave definition
	for entry in wave_def:
		var unit_id = entry.get("unit_id", "")
		var grid_pos = entry.get("grid_pos", Vector2i(0, 0))
		spawn_unit_by_id(unit_id, 1, grid_pos)

func roll_shop_offers() -> void:
	current_shop_offers.clear()
	sold_shop_offer_indices.clear()
	for i in range(shop_offer_count):
		var tier = roll_unit_tier_for_shop()
		var pool = get_shop_pool_for_tier(tier)
		if pool.is_empty():
			pool = get_shop_pool_for_tier(1)
		if pool.is_empty():
			print("No units available for shop roll")
			return
		var random_index = randi_range(0, pool.size() - 1)
		current_shop_offers.append(pool[random_index])

func get_shop_odds_for_level(level: int) -> Dictionary:
	var odds_level = clamp(level, 1, max_player_level)
	return shop_tier_odds.get(odds_level, shop_tier_odds[1])

func roll_unit_tier_for_shop() -> int:
	var odds = get_shop_odds_for_level(player_level)
	var total_weight = 0
	for tier in odds.keys():
		total_weight += odds[tier]

	if total_weight <= 0:
		return 1

	var roll = randi_range(1, total_weight)
	var running_total = 0
	for tier in odds.keys():
		running_total += odds[tier]
		if roll <= running_total:
			return tier

	return 1

func get_shop_pool_for_tier(tier: int) -> Array[String]:
	var pool: Array[String] = []
	for unit_id in shop_unit_ids:
		var data: Dictionary = unit_database.get_unit_data(unit_id)
		if data.is_empty():
			continue
		if data.get("tier", 1) == tier:
			pool.append(unit_id)
	return pool

func spawn_unit_by_id(unit_id: String, team_id: int, grid_pos: Vector2i, star_level: int = 1) -> CharacterBody3D:
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
	unit.set_meta("base_max_hp", unit.max_hp)
	unit.set_meta("base_damage", unit.damage)
	unit.set_meta("base_attack_cooldown", unit.attack_cooldown)
	unit.set_meta("base_attack_range", unit.attack_range)
	
	apply_star_level_to_unit(unit, star_level)
	unit.current_hp = unit.max_hp

	units_container.add_child(unit)
	unit.unit_clicked.connect(_on_unit_clicked)
	place_unit_on_grid(unit, grid_pos)
	unit.set_meta("star_level", star_level)
	if unit.has_method("set_star_level"):
		unit.set_star_level(star_level)

	print("Spawned unit: ", data["name"], " / faction: ", data["faction"], " / star: ", star_level)

	return unit

func apply_star_level_to_unit(unit: CharacterBody3D, star_level: int) -> void:
	if unit.has_method("set_star_level"):
		unit.set_star_level(star_level)
	var base_max_hp = unit.get_meta("base_max_hp", unit.max_hp)
	var base_damage = unit.get_meta("base_damage", unit.damage)
	unit.attack_cooldown = unit.get_meta("base_attack_cooldown", unit.attack_cooldown)
	unit.attack_range = unit.get_meta("base_attack_range", unit.attack_range)
	match star_level:
		1:
			unit.max_hp = base_max_hp
			unit.damage = base_damage
			return
		2:
			unit.max_hp = base_max_hp * 1.8
			unit.damage = base_damage * 1.8
			return
		3:
			unit.max_hp = base_max_hp * 3.2
			unit.damage = base_damage * 3.2
			return
		_:
			return

func get_player_faction_counts() -> Dictionary:
	var counts: Dictionary = {}
	for entry in player_roster:
		var unit_id = entry.get("unit_id", "")
		var data: Dictionary = unit_database.get_unit_data(unit_id)
		if data.is_empty():
			continue
		var faction = data.get("faction", "")
		if faction == "":
			continue
		counts[faction] = counts.get(faction, 0) + 1
	return counts

func get_active_faction_bonuses() -> Dictionary:
	var counts = get_player_faction_counts()
	var bonuses: Dictionary = {}
	if counts.get("Romans", 0) >= 2:
		bonuses["Romans"] = {"max_hp_multiplier": 1.2}
	if counts.get("Vikings", 0) >= 2:
		bonuses["Vikings"] = {"damage_multiplier": 1.2}
	if counts.get("Mongols", 0) >= 2:
		bonuses["Mongols"] = {"attack_range_multiplier": 1.15}
	if counts.get("Slavs", 0) >= 2:
		bonuses["Slavs"] = {"attack_cooldown_multiplier": 0.85}
	return bonuses

func get_player_role_counts() -> Dictionary:
	var counts: Dictionary = {}
	for entry in player_roster:
		var unit_id = entry.get("unit_id", "")
		var data: Dictionary = unit_database.get_unit_data(unit_id)
		if data.is_empty():
			continue
		var role = data.get("role", "")
		if role == "":
			continue
		counts[role] = counts.get(role, 0) + 1
	return counts

func get_active_role_bonuses() -> Dictionary:
	var counts = get_player_role_counts()
	var bonuses: Dictionary = {}
	if counts.get("Tank", 0) >= 2:
		bonuses["Tank"] = {"max_hp_multiplier": 1.2}
	if counts.get("Fighter", 0) >= 2:
		bonuses["Fighter"] = {"damage_multiplier": 1.15}
	if counts.get("Ranged", 0) >= 2:
		bonuses["Ranged"] = {"attack_range_multiplier": 1.1}
	return bonuses

func apply_faction_bonuses_to_unit(unit: CharacterBody3D, unit_id: String) -> void:
	if unit.team_id != 0:
		return

	var data: Dictionary = unit_database.get_unit_data(unit_id)
	if data.is_empty():
		return

	var faction = data.get("faction", "")
	var bonuses = get_active_faction_bonuses()
	if not bonuses.has(faction):
		return

	var bonus = bonuses[faction]
	unit.max_hp *= bonus.get("max_hp_multiplier", 1.0)
	unit.damage *= bonus.get("damage_multiplier", 1.0)
	unit.attack_range *= bonus.get("attack_range_multiplier", 1.0)
	unit.attack_cooldown *= bonus.get("attack_cooldown_multiplier", 1.0)

func apply_role_bonuses_to_unit(unit: CharacterBody3D, unit_id: String) -> void:
	if unit.team_id != 0:
		return

	var data: Dictionary = unit_database.get_unit_data(unit_id)
	if data.is_empty():
		return

	var role = data.get("role", "")
	var bonuses = get_active_role_bonuses()
	if not bonuses.has(role):
		return

	var bonus = bonuses[role]
	unit.max_hp *= bonus.get("max_hp_multiplier", 1.0)
	unit.damage *= bonus.get("damage_multiplier", 1.0)
	unit.attack_range *= bonus.get("attack_range_multiplier", 1.0)
	unit.attack_cooldown *= bonus.get("attack_cooldown_multiplier", 1.0)

func refresh_player_unit_bonuses() -> void:
	var units := get_tree().get_nodes_in_group("units")
	var active_faction_bonuses = get_active_faction_bonuses()
	var active_role_bonuses = get_active_role_bonuses()
	for unit in units:
		if not is_instance_valid(unit) or unit.is_queued_for_deletion():
			continue
		if unit.team_id != 0 or not unit.has_meta("roster_id"):
			continue

		var roster_id = unit.get_meta("roster_id")
		var roster_entry = null
		for entry in player_roster:
			if entry.get("roster_id", -1) == roster_id:
				roster_entry = entry
				break

		if roster_entry == null:
			continue

		var unit_id = roster_entry.get("unit_id", "")
		var star_level = roster_entry.get("star_level", 1)
		apply_star_level_to_unit(unit, star_level)
		apply_faction_bonuses_to_unit(unit, unit_id)
		apply_role_bonuses_to_unit(unit, unit_id)
		unit.set_meta("star_level", star_level)
		unit.current_hp = min(unit.current_hp, unit.max_hp)

	if not active_faction_bonuses.is_empty():
		print("Active faction bonuses: ", active_faction_bonuses.keys())
	if not active_role_bonuses.is_empty():
		print("Active role bonuses: ", active_role_bonuses.keys())
	update_synergy_label()
	update_unit_details_panel()

func get_roster_entry_for_unit(unit: CharacterBody3D):
	if unit == null or not is_instance_valid(unit):
		return null
	if not unit.has_meta("roster_id"):
		return null

	var roster_id = unit.get_meta("roster_id")
	for entry in player_roster:
		if entry.get("roster_id", -1) == roster_id:
			return entry
	return null

func get_unit_id_for_unit(unit: CharacterBody3D) -> String:
	var roster_entry = get_roster_entry_for_unit(unit)
	if roster_entry != null:
		return roster_entry.get("unit_id", unit.name)
	return unit.name

func update_unit_details_panel() -> void:
	if selected_unit == null or not is_instance_valid(selected_unit):
		unit_details_panel.visible = false
		return

	var unit_id = get_unit_id_for_unit(selected_unit)
	var data: Dictionary = unit_database.get_unit_data(unit_id)
	if data.is_empty():
		unit_details_panel.visible = false
		return

	var star_level = selected_unit.get("star_level")
	if selected_unit.has_meta("star_level"):
		star_level = selected_unit.get_meta("star_level")

	var sell_value = 0
	if selected_unit.team_id == 0:
		var roster_entry = get_roster_entry_for_unit(selected_unit)
		var roster_star = star_level
		if roster_entry != null:
			roster_star = roster_entry.get("star_level", star_level)
		sell_value = data["base_price"] * get_star_refund_multiplier(roster_star)

	var lines: Array[String] = [
		data.get("name", selected_unit.unit_name),
		"%s / %s" % [data.get("faction", ""), data.get("role", "")],
		"Tier: %d" % data.get("tier", 1),
		"Stars: %d" % star_level,
		"HP: %.0f / %.0f" % [selected_unit.current_hp, selected_unit.max_hp],
		"Damage: %.1f" % selected_unit.damage,
		"Range: %.1f" % selected_unit.attack_range,
		"Cooldown: %.2fs" % selected_unit.attack_cooldown
	]
	if selected_unit.team_id == 0:
		lines.append("Sell: %dg" % sell_value)

	unit_details_label.text = "\n".join(lines)
	unit_details_panel.visible = true

# Unit Selection and Movement
func _on_unit_clicked(unit: CharacterBody3D) -> void:
	if not is_preparation_phase():
		print("Cannot select unit outside preparation phase")
		return
	
	if unit.team_id != 0:
		print("Cannot select enemy unit")
		return
	
	clear_shop_selection()
	clear_bench_selection()
	
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
	update_unit_details_panel()
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

	if selected_bench_index >= 0 and selected_bench_index < bench_units.size():
		try_deploy_bench_unit(grid_pos)
		return

	if selected_unit == null or not is_instance_valid(selected_unit):
		print("No selected unit")
		return

	place_unit_on_grid(selected_unit, grid_pos)
	print("Moved selected unit to: ", grid_pos)
	clear_unit_selection()

func try_deploy_bench_unit(grid_pos: Vector2i) -> bool:
	if not is_preparation_phase():
		print("Cannot deploy bench unit outside preparation phase")
		return false

	if selected_bench_index < 0 or selected_bench_index >= bench_units.size():
		print("No bench unit selected")
		return false

	if grid_pos.y < 4:
		print("Cannot deploy to enemy half")
		return false

	if is_tile_occupied(grid_pos):
		print("Cannot deploy to occupied tile: ", grid_pos)
		return false

	if player_roster.size() >= max_player_units:
		print("Unit cap reached")
		return false

	var entry = bench_units[selected_bench_index]
	var unit_id = entry.get("unit_id", "")
	var star_level = entry.get("star_level", 1)
	var data: Dictionary = unit_database.get_unit_data(unit_id)
	if data.is_empty():
		print("Bench unit data not found for ", unit_id)
		return false

	add_player_roster_unit(unit_id, grid_pos, star_level)
	var unit = spawn_unit_by_id(unit_id, 0, grid_pos, star_level)
	if unit:
		unit.set_meta("roster_id", roster_id_counter)
	else:
		player_roster.remove_at(player_roster.size() - 1)
		print("Failed to spawn bench unit: ", data.get("name", unit_id))
		return false

	bench_units.remove_at(selected_bench_index)
	selected_bench_index = -1
	refresh_player_unit_bonuses()
	update_bench_ui()
	update_unit_cap_label()
	clear_all_selection()
	add_event_log("Deployed %s %d-star" % [data.get("name", unit_id), star_level])
	return true

func get_first_player_unit() -> CharacterBody3D:
	var units := get_tree().get_nodes_in_group("units")
	
	for unit in units:
		if unit.team_id == 0 and unit.current_hp > 0:
			return unit
	
	return null

# Battle
func _on_start_battle_button_pressed() -> void:
	print("BUTTON CLICKED")
	if game_over or victory:
		print("Cannot start battle after run has ended")
		return
	start_battle()

func start_battle() -> void:
	if not is_preparation_phase():
		return
	
	battle_started = true
	round_ended = false
	round_result_label.text = ""
	restart_button.visible = false
	
	clear_all_selection()
	
	add_event_log("Battle started")
	
	var units := get_tree().get_nodes_in_group("units")
	for unit in units:
		unit.start_battle()

func is_preparation_phase() -> bool:
	return not battle_started and not round_ended and not game_over and not victory

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
	if result_text == "PLAYER WINS" and round_number >= max_rounds:
		trigger_victory()
		return

	round_ended = true
	battle_started = false
	
	add_event_log("Round result: %s" % result_text)
	last_round_result = result_text
	round_result_label.text = result_text
	restart_button.visible = true

	if result_text == "ENEMY WINS":
		player_health = max(player_health - loss_damage, 0)
		update_player_health_label()
		print("PLAYER TAKES ", loss_damage, " DAMAGE. HP: ", player_health)
		if player_health <= 0:
			trigger_game_over()

	var units := get_tree().get_nodes_in_group("units")
	for unit in units:
		if is_instance_valid(unit):
			unit.stop_battle()

func _on_restart_round_button_pressed() -> void:
	print("RESTART CLICKED")
	if game_over or victory:
		reset_game()
	else:
		restart_round()

func restart_round() -> void:
	if game_over or victory:
		print("Cannot restart round after run has ended")
		return
	clear_units()
	
	battle_started = false
	round_ended = false
	round_result_label.text = ""
	restart_button.visible = false
	reset_battle_speed()
	clear_all_selection()
	round_number += 1
	player_gold += round_income
	
	if last_round_result == "PLAYER WINS":
		player_gold += win_bonus_gold
		add_event_log("Next round: +%dg income, +%dg win bonus" % [round_income, win_bonus_gold])
	elif last_round_result == "DRAW":
		player_gold += draw_bonus_gold
		add_event_log("Next round: +%dg income, +%dg draw bonus" % [round_income, draw_bonus_gold])
	else:
		add_event_log("Next round: +%dg income" % round_income)
	
	last_round_result = ""
	
	update_gold_label()
	update_round_label()
	update_unit_cap_label()
	update_synergy_label()
	roll_shop_offers()
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

func update_player_health_label() -> void:
	player_health_label.text = "HP: %d" % player_health

func update_round_label() -> void:
	round_label.text = "Round: %d / %d" % [round_number, max_rounds]

func get_xp_required_for_next_level() -> int:
	if player_level >= max_player_level:
		return 0
	return player_level * 2

func update_max_player_units() -> void:
	max_player_units = player_level + 1

func update_player_level_label() -> void:
	if player_level >= max_player_level:
		player_level_label.text = "Level: %d (MAX)" % player_level
		return
	player_level_label.text = "Level: %d (%d/%d XP)" % [player_level, player_xp, get_xp_required_for_next_level()]

func trigger_game_over() -> void:
	game_over = true
	battle_started = false
	round_ended = true
	round_result_label.text = "GAME OVER"
	restart_button.visible = true
	restart_button.text = "New Run"
	clear_all_selection()

	var units := get_tree().get_nodes_in_group("units")
	for unit in units:
		if is_instance_valid(unit):
			unit.stop_battle()

	add_event_log("Game over")

func trigger_victory() -> void:
	victory = true
	battle_started = false
	round_ended = true
	round_result_label.text = "VICTORY"
	restart_button.visible = true
	restart_button.text = "New Run"
	clear_all_selection()

	var units := get_tree().get_nodes_in_group("units")
	for unit in units:
		if is_instance_valid(unit):
			unit.stop_battle()

	add_event_log("VICTORY")

func reset_game() -> void:
	print("RESETTING GAME FOR NEW RUN")
	clear_units()
	
	# Reset all game state variables
	battle_started = false
	round_ended = false
	game_over = false
	victory = false
	round_number = 1
	last_round_result = ""
	player_gold = starting_gold
	player_health = starting_player_health
	player_level = 1
	player_xp = 0
	reset_battle_speed()
	update_max_player_units()
	event_log.clear()
	
	# Clear rosters and bench
	player_roster.clear()
	bench_units.clear()
	roster_id_counter = 0
	selected_bench_index = -1
	
	# Clear selection state
	clear_all_selection()
	
	# Reset UI
	round_result_label.text = ""
	restart_button.visible = false
	restart_button.text = "Next Round"
	
	# Update UI labels
	update_gold_label()
	update_player_health_label()
	update_player_level_label()
	update_unit_cap_label()
	update_synergy_label()
	update_bench_ui()
	update_round_label()
	
	# Roll fresh shop and populate
	roll_shop_offers()
	populate_shop()
	
	# Spawn starting units
	spawn_test_units()
	add_event_log("New run started")

# Shop
func populate_shop() -> void:
	clear_shop()
	
	for i in range(current_shop_offers.size()):
		var unit_id = current_shop_offers[i]
		var data: Dictionary = unit_database.get_unit_data(unit_id)
		
		if data.is_empty():
			continue
		
		var card := Button.new()
		card.custom_minimum_size = Vector2(220, 85)
		
		if i in sold_shop_offer_indices:
			card.text = "SOLD"
			card.disabled = true
		else:
			var can_afford = player_gold >= data["base_price"]
			card.text = "%s\n%s / %s\nTier %d\nCost: %dg" % [
				data["name"],
				data["faction"],
				data["role"],
				data.get("tier", 1),
				data["base_price"]
			]
			card.disabled = not can_afford
			card.pressed.connect(_on_shop_card_pressed.bind(unit_id, i))
		
		shop_items.add_child(card)

func clear_shop() -> void:
	for child in shop_items.get_children():
		child.queue_free()

func _on_buy_xp_button_pressed() -> void:
	if not is_preparation_phase():
		print("Cannot buy XP outside preparation phase")
		return

	if player_level >= max_player_level:
		print("Player is already at max level")
		return

	if player_gold < xp_purchase_cost:
		print("Cannot afford XP. Need ", xp_purchase_cost, " gold, have ", player_gold)
		return

	player_gold -= xp_purchase_cost
	player_xp += xp_per_purchase
	print("Bought ", xp_per_purchase, " XP for ", xp_purchase_cost, " gold")

	while player_level < max_player_level:
		var required_xp = get_xp_required_for_next_level()
		if player_xp < required_xp:
			break

		player_xp -= required_xp
		player_level += 1
		update_max_player_units()
		add_event_log("Level up: %d (unit cap %d)" % [player_level, max_player_units])

	if player_level >= max_player_level:
		player_xp = 0

	update_gold_label()
	update_player_level_label()
	update_unit_cap_label()

func _on_shop_card_pressed(unit_id: String, offer_index: int) -> void:
	if not is_preparation_phase():
		print("Cannot buy outside preparation phase")
		return
	
	var data: Dictionary = unit_database.get_unit_data(unit_id)
	
	if data.is_empty():
		return
	
	var cost = data["base_price"]
	if offer_index in sold_shop_offer_indices:
		print("Shop slot ", offer_index, " is already sold")
		return
	if player_gold < cost:
		print("Cannot afford ", data["name"], ". Need ", cost, " gold, have ", player_gold)
		return

	if bench_units.size() >= max_bench_units:
		print("Bench is full")
		return
	
	player_gold -= cost
	bench_units.append({"unit_id": unit_id, "star_level": 1})
	sold_shop_offer_indices.append(offer_index)
	add_event_log("Bought %s to bench for %dg" % [data["name"], cost])
	update_gold_label()
	try_merge_bench_units()
	update_bench_ui()
	populate_shop()
	clear_all_selection()

func try_merge_bench_units() -> void:
	var merged_any = false
	while true:
		if try_merge_deployed_unit_with_bench():
			merged_any = true
			continue

		var merge_sets: Dictionary = {}
		for i in range(bench_units.size()):
			var entry = bench_units[i]
			var unit_id = entry.get("unit_id", "")
			var star_level = entry.get("star_level", 1)
			if star_level >= 3:
				continue
			var merge_key = "%s:%d" % [unit_id, star_level]
			if not merge_sets.has(merge_key):
				merge_sets[merge_key] = {"unit_id": unit_id, "star_level": star_level, "indices": []}
			merge_sets[merge_key]["indices"].append(i)

		var found_merge = false
		for merge_key in merge_sets.keys():
			var merge_set = merge_sets[merge_key]
			var indices = merge_set["indices"]
			if indices.size() >= 3:
				indices.sort()
				for j in range(indices.size() - 1, -1, -1):
					bench_units.remove_at(indices[j])
				var unit_id = merge_set["unit_id"]
				var star_level = merge_set["star_level"]
				var upgraded_star = star_level + 1
				bench_units.append({"unit_id": unit_id, "star_level": upgraded_star})
				var data: Dictionary = unit_database.get_unit_data(unit_id)
				add_event_log("Merged %s into %d-star" % [data.get("name", unit_id), upgraded_star])
				found_merge = true
				merged_any = true
				break

		if not found_merge:
			break

	if merged_any:
		update_bench_ui()
		update_unit_cap_label()

func try_merge_deployed_unit_with_bench() -> bool:
	for roster_index in range(player_roster.size()):
		var roster_entry = player_roster[roster_index]
		var unit_id = roster_entry.get("unit_id", "")
		var star_level = roster_entry.get("star_level", 1)
		if unit_id == "" or star_level >= 3:
			continue

		var bench_indices: Array[int] = []
		for bench_index in range(bench_units.size()):
			var bench_entry = bench_units[bench_index]
			if bench_entry.get("unit_id", "") == unit_id and bench_entry.get("star_level", 1) == star_level:
				bench_indices.append(bench_index)
				if bench_indices.size() == 2:
					break

		if bench_indices.size() < 2:
			continue

		for i in range(bench_indices.size() - 1, -1, -1):
			bench_units.remove_at(bench_indices[i])

		var upgraded_star = star_level + 1
		player_roster[roster_index]["star_level"] = upgraded_star
		var roster_id = roster_entry.get("roster_id", -1)
		refresh_player_unit_bonuses()
		var unit = find_player_unit_by_roster_id(roster_id)
		if unit:
			unit.current_hp = unit.max_hp

		var data: Dictionary = unit_database.get_unit_data(unit_id)
		add_event_log("Merged deployed %s into %d-star" % [data.get("name", unit_id), upgraded_star])
		return true

	return false

func find_player_unit_by_roster_id(roster_id: int) -> CharacterBody3D:
	if roster_id < 0:
		return null

	var units := get_tree().get_nodes_in_group("units")
	for unit in units:
		if unit.is_queued_for_deletion():
			continue
		if unit.team_id == 0 and unit.has_meta("roster_id") and unit.get_meta("roster_id") == roster_id:
			return unit

	return null

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
	
	if selected_bench_index >= 0 and selected_bench_index < bench_units.size():
		var entry = bench_units[selected_bench_index]
		var bench_unit_id = entry.get("unit_id", "")
		var bench_star = entry.get("star_level", 1)
		var bench_data: Dictionary = unit_database.get_unit_data(bench_unit_id)
		if bench_data.is_empty():
			print("Bench unit data not found for ", bench_unit_id)
			return
		
		var bench_refund = bench_data["base_price"] * get_star_refund_multiplier(bench_star)
		player_gold += bench_refund
		bench_units.remove_at(selected_bench_index)
		selected_bench_index = -1
		update_gold_label()
		update_bench_ui()
		populate_shop()
		clear_all_selection()
		add_event_log("Sold bench %s %d-star for %dg" % [bench_data["name"], bench_star, bench_refund])
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
	
	var deployed_unit_id = roster_entry["unit_id"]
	var deployed_star = roster_entry.get("star_level", 1)
	var deployed_data = unit_database.get_unit_data(deployed_unit_id)
	
	if deployed_data.is_empty():
		print("Unit data not found for unit_id ", deployed_unit_id)
		return
	
	var deployed_refund = deployed_data["base_price"] * get_star_refund_multiplier(deployed_star)
	
	player_gold += deployed_refund
	player_roster.remove_at(roster_index)
	selected_unit.queue_free()
	clear_all_selection()
	refresh_player_unit_bonuses()
	
	update_gold_label()
	update_unit_cap_label()
	populate_shop()
	add_event_log("Sold %s %d-star for %dg" % [deployed_data["name"], deployed_star, deployed_refund])

func get_star_refund_multiplier(star_level: int) -> int:
	match star_level:
		2:
			return 3
		3:
			return 9
		_:
			return 1

# UI
func update_gold_label() -> void:
	gold_label.text = "Gold: %d" % player_gold

func update_unit_cap_label() -> void:
	unit_cap_label.text = "Units: %d / %d" % [player_roster.size(), max_player_units]

func update_synergy_label() -> void:
	var faction_counts = get_player_faction_counts()
	var role_counts = get_player_role_counts()
	var active_faction_bonuses = get_active_faction_bonuses()
	var active_role_bonuses = get_active_role_bonuses()
	if active_faction_bonuses.is_empty() and active_role_bonuses.is_empty():
		synergy_label.text = "Synergies: None"
		return

	var lines: Array[String] = ["Synergies:"]
	if active_faction_bonuses.has("Romans"):
		lines.append("Romans %d/2: +HP" % faction_counts.get("Romans", 0))
	if active_faction_bonuses.has("Vikings"):
		lines.append("Vikings %d/2: +DMG" % faction_counts.get("Vikings", 0))
	if active_faction_bonuses.has("Mongols"):
		lines.append("Mongols %d/2: +RNG" % faction_counts.get("Mongols", 0))
	if active_faction_bonuses.has("Slavs"):
		lines.append("Slavs %d/2: +AS" % faction_counts.get("Slavs", 0))
	if active_role_bonuses.has("Tank"):
		lines.append("Tank %d/2: +HP" % role_counts.get("Tank", 0))
	if active_role_bonuses.has("Fighter"):
		lines.append("Fighter %d/2: +DMG" % role_counts.get("Fighter", 0))
	if active_role_bonuses.has("Ranged"):
		lines.append("Ranged %d/2: +RNG" % role_counts.get("Ranged", 0))
	synergy_label.text = "\n".join(lines)

func update_bench_ui() -> void:
	bench_label.text = "Bench: %d / %d" % [bench_units.size(), max_bench_units]
	for child in bench_items.get_children():
		child.queue_free()

	for i in range(bench_units.size()):
		var entry = bench_units[i]
		var button = Button.new()
		button.custom_minimum_size = Vector2(220, 70)
		button.text = get_bench_unit_display_name(entry)
		button.pressed.connect(_on_bench_unit_pressed.bind(i))
		bench_items.add_child(button)

func get_bench_unit_display_name(entry: Dictionary) -> String:
	var unit_id = entry.get("unit_id", "")
	var data: Dictionary = unit_database.get_unit_data(unit_id)
	var star_level = entry.get("star_level", 1)
	var name = data.get("name", unit_id)
	return "%s %s\nTier %d" % [name, "★".repeat(clamp(star_level, 1, 3)), data.get("tier", 1)]

func _on_bench_unit_pressed(index: int) -> void:
	if not is_preparation_phase():
		print("Cannot select bench unit outside preparation phase")
		return

	if index < 0 or index >= bench_units.size():
		print("Bench index out of range: ", index)
		return

	selected_bench_index = index
	clear_shop_selection()
	clear_unit_selection()
	var unit_id = bench_units[index].get("unit_id", "")
	var data: Dictionary = unit_database.get_unit_data(unit_id)
	print("SELECTED BENCH UNIT: ", data.get("name", unit_id))
