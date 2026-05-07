extends Node3D

# References
@onready var board: Node3D = $Board
@onready var units_container: Node3D = $Units
@onready var audio_manager: Node = $AudioManager
@onready var camera: Camera3D = $Camera3D
@onready var start_button: Button = $UI/MainLayout/RootColumns/LeftSidebar/StartBattleButton
@onready var battle_speed_button: Button = $UI/MainLayout/RootColumns/LeftSidebar/BattleSpeedButton
@onready var camera_zoom_button: Button = $UI/MainLayout/RootColumns/LeftSidebar/CameraZoomButton
@onready var mute_button: Button = $UI/MainLayout/RootColumns/LeftSidebar/MuteButton
@onready var restart_button: Button = $UI/MainLayout/RootColumns/LeftSidebar/RestartRoundButton
@onready var round_result_label: Label = $UI/MainLayout/RootColumns/LeftSidebar/RoundResultLabel
@onready var unit_details_panel: Panel = $UI/MainLayout/RootColumns/RightSidebar/UnitDetailsPanel
@onready var unit_details_label: Label = $UI/MainLayout/RootColumns/RightSidebar/UnitDetailsPanel/UnitDetailsMargin/UnitDetailsLabel
@onready var event_log_label: Label = $UI/MainLayout/RootColumns/RightSidebar/EventLogPanel/EventLogMargin/EventLogScroll/EventLogLabel
@onready var action_feedback_label: Label = $UI/MainLayout/RootColumns/CenterArea/ActionFeedbackLabel
@onready var item_label: Label = $UI/MainLayout/RootColumns/RightSidebar/ItemPanel/ItemMargin/ItemContent/ItemLabel
@onready var item_items: HBoxContainer = $UI/MainLayout/RootColumns/RightSidebar/ItemPanel/ItemMargin/ItemContent/ItemScroll/ItemItems
@onready var shop_items: HBoxContainer = $UI/MainLayout/RootColumns/CenterArea/BottomArea/ShopPanel/ShopMargin/ShopScroll/ShopItems
@onready var gold_label: Label = $UI/MainLayout/RootColumns/LeftSidebar/GoldLabel
@onready var player_level_label: Label = $UI/MainLayout/RootColumns/LeftSidebar/PlayerLevelLabel
@onready var round_label: Label = $UI/MainLayout/RootColumns/LeftSidebar/RoundLabel
@onready var reroll_button: Button = $UI/MainLayout/RootColumns/LeftSidebar/RerollButton
@onready var buy_xp_button: Button = $UI/MainLayout/RootColumns/LeftSidebar/BuyXPButton
@onready var use_self_as_opponent_button: Button = $UI/MainLayout/RootColumns/RightSidebar/DebugPanel/DebugMargin/DebugContent/UseSelfAsOpponentButton
@onready var sell_unit_button: Button = $UI/MainLayout/RootColumns/LeftSidebar/SellUnitButton
@onready var unit_cap_label: Label = $UI/MainLayout/RootColumns/LeftSidebar/UnitCapLabel
@onready var synergy_label: Label = $UI/MainLayout/RootColumns/LeftSidebar/SynergyLabel
@onready var player_health_label: Label = $UI/MainLayout/RootColumns/LeftSidebar/PlayerHealthLabel
@onready var bench_label: Label = $UI/MainLayout/RootColumns/CenterArea/BottomArea/BenchPanel/BenchMargin/BenchContent/BenchLabel
@onready var bench_items: HBoxContainer = $UI/MainLayout/RootColumns/CenterArea/BottomArea/BenchPanel/BenchMargin/BenchContent/BenchScroll/BenchItems

# Resources
var unit_scene: PackedScene = preload("res://units/Unit.tscn")
var unit_database = preload("res://scripts/unit_database.gd")
var item_database = preload("res://scripts/item_database.gd")
var enemy_wave_database = preload("res://scripts/enemy_wave_database.gd")
var economy_rules = preload("res://scripts/economy_rules.gd")
var synergy_rules = preload("res://scripts/synergy_rules.gd")
var battle_snapshot = preload("res://scripts/battle_snapshot.gd")

# State
var battle_started: bool = false
var round_ended: bool = false
var selected_unit: CharacterBody3D = null
var selected_shop_unit_id: String = ""
var battle_speed_values: Array[float] = [1.0, 2.0, 4.0]
var battle_speed_index: int = 0
var camera_zoom_levels: Array[float] = [0.8, 1.0, 1.2]
var camera_zoom_index: int = 1
var default_camera_position: Vector3 = Vector3.ZERO
var camera_focus_position: Vector3 = Vector3.ZERO
var event_log: Array[String] = []
var max_event_log_entries: int = 8
var last_battle_summary: Dictionary = {}
var current_battle_id: int = 0
var current_battle_seed: int = 0
var current_battle_payload: Dictionary = {}
var battle_history: Array[Dictionary] = []
var max_battle_history_entries: int = 20
var export_battle_summaries: bool = false
var battle_summary_export_dir: String = "user://battle_summaries"
var action_feedback_timer: Timer = null

# UI Style
var ui_dark_stone_color: Color = Color(0.10, 0.11, 0.10, 0.92)
var ui_stone_color: Color = Color(0.18, 0.18, 0.16, 0.96)
var ui_stone_hover_color: Color = Color(0.24, 0.22, 0.18, 0.98)
var ui_brass_color: Color = Color(0.76, 0.55, 0.25)
var ui_gold_color: Color = Color(0.95, 0.78, 0.36)
var ui_light_text_color: Color = Color(0.92, 0.88, 0.76)
var ui_muted_text_color: Color = Color(0.58, 0.54, 0.45)

# Selection Helpers
func clear_shop_selection() -> void:
	selected_shop_unit_id = ""

func clear_unit_selection() -> void:
	if selected_unit != null and is_instance_valid(selected_unit):
		selected_unit.set_selected(false)
	selected_unit = null
	update_unit_details_panel()
	if board != null and board.has_method("clear_tile_highlights"):
		board.clear_tile_highlights()

func clear_bench_selection() -> void:
	selected_bench_index = -1
	if board != null and board.has_method("clear_tile_highlights"):
		board.clear_tile_highlights()

func clear_item_selection() -> void:
	selected_item_index = -1

func clear_all_selection() -> void:
	clear_shop_selection()
	clear_unit_selection()
	clear_bench_selection()
	clear_item_selection()
	if board != null and board.has_method("clear_tile_highlights"):
		board.clear_tile_highlights()

func show_action_feedback(message: String) -> void:
	if action_feedback_label == null:
		return
	action_feedback_label.text = message
	action_feedback_label.visible = true
	if action_feedback_timer != null:
		action_feedback_timer.start()

func clear_action_feedback() -> void:
	if action_feedback_timer != null:
		action_feedback_timer.stop()
	if action_feedback_label == null:
		return
	action_feedback_label.text = ""
	action_feedback_label.visible = false

func setup_action_feedback_timer() -> void:
	action_feedback_timer = Timer.new()
	action_feedback_timer.one_shot = true
	action_feedback_timer.wait_time = 1.5
	action_feedback_timer.timeout.connect(clear_action_feedback)
	add_child(action_feedback_timer)

func get_blocked_action_feedback() -> String:
	if battle_started:
		return "Battle in progress"
	if game_over or victory:
		return "Run ended"
	if round_ended:
		return "Round ended"
	return "Not available"

func apply_ui_style() -> void:
	var panel_paths := [
		"UI/MainLayout/RootColumns/CenterArea/BottomArea/BenchPanel",
		"UI/MainLayout/RootColumns/CenterArea/BottomArea/ShopPanel",
		"UI/MainLayout/RootColumns/RightSidebar/UnitDetailsPanel",
		"UI/MainLayout/RootColumns/RightSidebar/EventLogPanel",
		"UI/MainLayout/RootColumns/RightSidebar/ItemPanel",
		"UI/MainLayout/RootColumns/RightSidebar/DebugPanel"
	]
	for panel_path in panel_paths:
		var panel := get_node_or_null(panel_path)
		if panel is Panel:
			if panel.name == "BenchPanel":
				style_bench_panel(panel)
			else:
				style_panel(panel)

	style_labels_under($UI)
	style_buttons_under($UI)
	style_action_feedback_label()

func style_panel(panel: Panel) -> void:
	panel.add_theme_stylebox_override("panel", create_ui_stylebox(ui_dark_stone_color, ui_brass_color, 2, 4))

func style_bench_panel(panel: Panel) -> void:
	var style := create_ui_stylebox(Color(0.08, 0.08, 0.07, 0.58), Color(0.58, 0.48, 0.28, 0.88), 1, 2)
	style.border_width_top = 3
	style.border_width_bottom = 1
	style.content_margin_left = 6
	style.content_margin_top = 2
	style.content_margin_right = 6
	style.content_margin_bottom = 3
	panel.add_theme_stylebox_override("panel", style)

func style_bench_slot_button(button: Button, faction: String) -> void:
	var faction_color := get_faction_card_color(faction)
	var bg_color := Color(0.10, 0.10, 0.09, 0.88).lerp(faction_color, 0.12)
	var hover_color := Color(0.18, 0.17, 0.14, 0.96).lerp(faction_color, 0.18)
	button.add_theme_stylebox_override("normal", create_ui_stylebox(bg_color, Color(0.46, 0.38, 0.23, 0.88), 1, 2))
	button.add_theme_stylebox_override("hover", create_ui_stylebox(hover_color, ui_gold_color, 2, 2))
	button.add_theme_stylebox_override("pressed", create_ui_stylebox(Color(0.10, 0.09, 0.07, 0.98), ui_gold_color, 2, 2))
	button.add_theme_color_override("font_color", ui_light_text_color)
	button.add_theme_color_override("font_hover_color", ui_gold_color)
	button.add_theme_color_override("font_pressed_color", ui_gold_color)

func style_buttons_under(node: Node) -> void:
	for child in node.get_children():
		if child is Button:
			style_button(child)
		style_buttons_under(child)

func style_labels_under(node: Node) -> void:
	for child in node.get_children():
		if child is Label:
			style_label(child)
		style_labels_under(child)

func style_label(label: Label) -> void:
	label.add_theme_color_override("font_color", ui_light_text_color)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.65))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)

func style_action_feedback_label() -> void:
	action_feedback_label.add_theme_color_override("font_color", ui_gold_color)
	action_feedback_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	action_feedback_label.add_theme_constant_override("shadow_offset_x", 1)
	action_feedback_label.add_theme_constant_override("shadow_offset_y", 1)

func style_button(button: Button) -> void:
	button.add_theme_stylebox_override("normal", create_ui_stylebox(ui_stone_color, ui_brass_color, 1, 4))
	button.add_theme_stylebox_override("hover", create_ui_stylebox(ui_stone_hover_color, ui_gold_color, 2, 4))
	button.add_theme_stylebox_override("pressed", create_ui_stylebox(Color(0.12, 0.10, 0.08, 0.98), ui_gold_color, 2, 4))
	button.add_theme_stylebox_override("disabled", create_ui_stylebox(Color(0.08, 0.08, 0.08, 0.72), Color(0.25, 0.22, 0.16, 0.85), 1, 4))
	button.add_theme_color_override("font_color", ui_light_text_color)
	button.add_theme_color_override("font_hover_color", ui_gold_color)
	button.add_theme_color_override("font_pressed_color", ui_gold_color)
	button.add_theme_color_override("font_disabled_color", ui_muted_text_color)

func style_unit_card_button(button: Button, faction: String, disabled_card: bool = false) -> void:
	var faction_color := get_faction_card_color(faction)
	var bg_color := ui_stone_color.lerp(faction_color, 0.20)
	var hover_color := ui_stone_hover_color.lerp(faction_color, 0.24)
	if disabled_card:
		bg_color = Color(0.08, 0.08, 0.08, 0.78)
		hover_color = bg_color
	button.add_theme_stylebox_override("normal", create_ui_stylebox(bg_color, faction_color.lerp(ui_brass_color, 0.35), 2, 4))
	button.add_theme_stylebox_override("hover", create_ui_stylebox(hover_color, ui_gold_color, 2, 4))
	button.add_theme_stylebox_override("pressed", create_ui_stylebox(Color(0.12, 0.10, 0.08, 0.98), ui_gold_color, 2, 4))
	button.add_theme_stylebox_override("disabled", create_ui_stylebox(bg_color, Color(0.26, 0.23, 0.18, 0.85), 1, 4))
	button.add_theme_color_override("font_color", ui_light_text_color)
	button.add_theme_color_override("font_hover_color", ui_gold_color)
	button.add_theme_color_override("font_pressed_color", ui_gold_color)
	button.add_theme_color_override("font_disabled_color", ui_muted_text_color if disabled_card else ui_light_text_color)

func style_sold_card_button(button: Button) -> void:
	button.add_theme_stylebox_override("disabled", create_ui_stylebox(Color(0.11, 0.09, 0.08, 0.92), Color(0.45, 0.32, 0.16, 0.9), 2, 4))
	button.add_theme_color_override("font_disabled_color", Color(0.78, 0.52, 0.28))

func get_faction_card_color(faction: String) -> Color:
	match faction:
		"Romans":
			return Color(0.62, 0.12, 0.10)
		"Vikings":
			return Color(0.20, 0.30, 0.42)
		"Slavs":
			return Color(0.26, 0.42, 0.22)
		"Mongols":
			return Color(0.70, 0.50, 0.22)
		_:
			return ui_brass_color

func create_ui_stylebox(bg_color: Color, border_color: Color, border_width: int, corner_radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	style.corner_radius_bottom_right = corner_radius
	style.corner_radius_bottom_left = corner_radius
	style.content_margin_left = 8
	style.content_margin_top = 6
	style.content_margin_right = 8
	style.content_margin_bottom = 6
	return style

func play_audio_event(event_name: String) -> void:
	if audio_manager == null:
		return

	var method_name = "play_%s" % event_name
	if audio_manager.has_method(method_name):
		audio_manager.call(method_name)

func update_mute_button_text() -> void:
	if mute_button == null:
		return

	var audio_muted := false
	if audio_manager != null and audio_manager.has_method("is_muted"):
		audio_muted = audio_manager.call("is_muted")
	mute_button.text = "Sound: Off" if audio_muted else "Sound: On"

func _on_mute_button_pressed() -> void:
	if audio_manager != null and audio_manager.has_method("toggle_muted"):
		audio_manager.call("toggle_muted")
	update_mute_button_text()

# Economy
var starting_gold: int = 10
var round_income: int = 5
var reroll_cost: int = 2
var win_bonus_gold: int = 2
var draw_bonus_gold: int = 1
var interest_cap: int = 5
var win_streak: int = 0
var loss_streak: int = 0
var max_streak_bonus: int = 2
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

var player_roster: Array[Dictionary] = []
var roster_id_counter: int = 0
var round_number: int = 1
var last_round_result: String = ""
var bench_units: Array[Dictionary] = []
var max_bench_units: int = 6
var selected_bench_index: int = -1
var item_inventory: Array[String] = []
var selected_item_index: int = -1
var use_snapshot_opponent: bool = false
var opponent_army_snapshot: Array[Dictionary] = []

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
	setup_action_feedback_timer()
	apply_ui_style()
	
	round_result_label.text = ""
	restart_button.visible = false
	apply_battle_speed()
	update_battle_speed_ui()
	update_mute_button_text()
	setup_camera_defaults()
	apply_camera_zoom()
	update_camera_zoom_button()
	clear_action_feedback()
	add_event_log("New run started")

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
	update_item_ui()

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

func setup_camera_defaults() -> void:
	if camera == null:
		return
	default_camera_position = camera.global_position
	camera_focus_position = Vector3(0.0, 0.75, 1.65)
	focus_camera_on_board()

func focus_camera_on_board() -> void:
	if camera == null:
		return
	camera.look_at(camera_focus_position, Vector3.UP)

func apply_camera_zoom() -> void:
	if camera == null:
		return
	var zoom := camera_zoom_levels[camera_zoom_index]
	var default_offset := default_camera_position - camera_focus_position
	if default_offset == Vector3.ZERO:
		default_offset = camera.global_position - camera_focus_position
	camera.global_position = camera_focus_position + default_offset / zoom
	focus_camera_on_board()

func update_camera_zoom_button() -> void:
	if camera_zoom_button == null:
		return
	var zoom := camera_zoom_levels[camera_zoom_index]
	var zoom_text := str(zoom)
	if is_equal_approx(zoom, float(int(zoom))):
		zoom_text = str(int(zoom))
	camera_zoom_button.text = "Zoom: %sx" % zoom_text

func reset_camera_zoom() -> void:
	camera_zoom_index = 1
	apply_camera_zoom()
	update_camera_zoom_button()

func _on_camera_zoom_button_pressed() -> void:
	camera_zoom_index = (camera_zoom_index + 1) % camera_zoom_levels.size()
	apply_camera_zoom()
	update_camera_zoom_button()
	print("Camera zoom set to ", camera_zoom_levels[camera_zoom_index], "x")

# Spawning
func spawn_test_units() -> void:
	add_player_roster_unit("roman_legionary", Vector2i(2, 6))
	add_player_roster_unit("roman_archer", Vector2i(4, 7))
	spawn_player_roster()
	spawn_opponent_army(1)

func add_player_roster_unit(unit_id: String, grid_pos: Vector2i, star_level: int = 1, item_ids: Array[String] = []) -> void:
	roster_id_counter += 1
	player_roster.append({
		"roster_id": roster_id_counter,
		"unit_id": unit_id,
		"grid_pos": grid_pos,
		"star_level": star_level,
		"item_ids": item_ids.duplicate()
	})
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

func create_player_army_snapshot() -> Array[Dictionary]:
	return battle_snapshot.create_army_snapshot_from_roster(player_roster)

func create_spawned_opponent_army_snapshot() -> Array[Dictionary]:
	var snapshot: Array[Dictionary] = []
	var units := get_tree().get_nodes_in_group("units")
	for unit in units:
		if not is_instance_valid(unit) or unit.team_id != 1:
			continue
		snapshot.append(create_army_snapshot_entry_from_unit(unit))
	return snapshot

func create_army_snapshot_entry_from_unit(unit: CharacterBody3D) -> Dictionary:
	return battle_snapshot.create_unit_snapshot_from_unit(unit)

func get_unit_star_level(unit: CharacterBody3D) -> int:
	return battle_snapshot.get_unit_star_level(unit)

func mirror_grid_pos_for_opponent(grid_pos: Vector2i) -> Vector2i:
	return battle_snapshot.mirror_grid_pos_for_opponent(grid_pos)

func spawn_opponent_army(round_num: int) -> void:
	# Opponent army = enemy team units for the current battle.
	if use_snapshot_opponent and not opponent_army_snapshot.is_empty():
		spawn_opponent_army_from_snapshot(opponent_army_snapshot)
		return

	# For now, the PvE wave generator is the fallback temporary source of that army.
	spawn_enemy_wave(round_num)

func spawn_opponent_army_from_snapshot(snapshot: Array[Dictionary]) -> void:
	for entry in snapshot:
		var unit_id = entry.get("unit_id", "")
		var grid_pos = mirror_grid_pos_for_opponent(entry.get("grid_pos", Vector2i.ZERO))
		var star_level = entry.get("star_level", 1)
		spawn_unit_by_id(unit_id, 1, grid_pos, star_level)

func clear_opponent_units() -> void:
	var units := get_tree().get_nodes_in_group("units")
	for unit in units:
		if is_instance_valid(unit) and unit.team_id == 1:
			unit.queue_free()

func spawn_enemy_wave(round_num: int) -> void:
	# Temporary PvE wave generator used as the current opponent army source.
	# Use exact definition if it exists, otherwise use the highest available.
	var wave_def = enemy_wave_database.get_wave_definition(round_num)
	
	# Spawn all enemy team units in the wave definition.
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
	unit.faction = data["faction"]
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
	return synergy_rules.count_factions(player_roster, unit_database)

func get_active_faction_bonuses() -> Dictionary:
	return synergy_rules.get_active_faction_bonuses(get_player_faction_counts())

func get_player_role_counts() -> Dictionary:
	return synergy_rules.count_roles(player_roster, unit_database)

func get_active_role_bonuses() -> Dictionary:
	return synergy_rules.get_active_role_bonuses(get_player_role_counts())

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

func apply_item_bonuses_to_unit(unit: CharacterBody3D, item_ids: Array) -> void:
	if unit.team_id != 0:
		return

	for item_id in item_ids:
		var item_data = get_item_data(item_id)
		if item_data.is_empty():
			continue
		unit.max_hp += item_data.get("max_hp_bonus", 0.0)
		unit.damage += item_data.get("damage_bonus", 0.0)
		unit.attack_range += item_data.get("attack_range_bonus", 0.0)
		unit.attack_cooldown *= item_data.get("attack_cooldown_multiplier", 1.0)

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
		apply_item_bonuses_to_unit(unit, roster_entry.get("item_ids", []))
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

func get_unit_effective_stats_summary(unit: CharacterBody3D) -> Dictionary:
	if unit == null or not is_instance_valid(unit):
		return {}

	var unit_id = get_unit_id_for_unit(unit)
	var data: Dictionary = unit_database.get_unit_data(unit_id)
	var roster_entry = get_roster_entry_for_unit(unit)
	var star_level = unit.star_level
	if unit.has_meta("star_level"):
		star_level = unit.get_meta("star_level")
	if roster_entry != null:
		star_level = roster_entry.get("star_level", star_level)

	return {
		"unit_id": unit_id,
		"unit_name": data.get("name", unit.unit_name),
		"team_id": unit.team_id,
		"star_level": star_level,
		"current_hp": unit.current_hp,
		"max_hp": unit.max_hp,
		"damage": unit.damage,
		"attack_range": unit.attack_range,
		"attack_cooldown": unit.attack_cooldown,
		"faction": data.get("faction", ""),
		"role": data.get("role", unit.role),
		"tier": data.get("tier", 1),
		"item_ids": roster_entry.get("item_ids", []).duplicate() if roster_entry != null else []
	}

func get_player_army_stats_summary() -> Array[Dictionary]:
	var summaries: Array[Dictionary] = []
	var units := get_tree().get_nodes_in_group("units")
	for unit in units:
		if not is_instance_valid(unit) or unit.team_id != 0:
			continue
		var summary := get_unit_effective_stats_summary(unit)
		if not summary.is_empty():
			summaries.append(summary)
	return summaries

func print_player_army_stats_summary() -> void:
	print("Player Army Stats Summary:")
	for summary in get_player_army_stats_summary():
		print(summary)

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
		var item_text = "Item: None"
		var details_roster_entry = get_roster_entry_for_unit(selected_unit)
		if details_roster_entry != null:
			var item_ids = details_roster_entry.get("item_ids", [])
			if not item_ids.is_empty():
				item_text = "Item: %s" % get_item_name(item_ids[0])
		lines.append(item_text)
		lines.append("Sell: %dg" % sell_value)

	unit_details_label.text = "\n".join(lines)
	unit_details_panel.visible = true

# Unit Selection and Movement
func _on_unit_clicked(unit: CharacterBody3D) -> void:
	if not is_preparation_phase():
		show_action_feedback(get_blocked_action_feedback())
		print("Cannot select unit outside preparation phase")
		return
	
	if unit.team_id != 0:
		show_action_feedback("Cannot select enemy")
		print("Cannot select enemy unit")
		return

	if selected_item_index >= 0:
		equip_selected_item_to_unit(unit)
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
	if board != null and board.has_method("highlight_tiles"):
		board.highlight_tiles(get_valid_player_empty_tiles())
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

func get_valid_player_empty_tiles() -> Array[Vector2i]:
	var valid_tiles: Array[Vector2i] = []
	var board_width := 8
	var board_height := 8
	if board != null:
		board_width = int(board.width)
		board_height = int(board.height)
	var player_start_y := floori(float(board_height) / 2.0)
	
	for y in range(player_start_y, board_height):
		for x in range(board_width):
			var grid_pos := Vector2i(x, y)
			if not is_tile_occupied(grid_pos):
				valid_tiles.append(grid_pos)
	
	return valid_tiles

# Board Interaction
func _on_board_tile_clicked(grid_pos: Vector2i) -> void:
	print("BOARD TILE CLICK HANDLER: ", grid_pos, " selected_bench_index: ", selected_bench_index)
	if not is_preparation_phase():
		show_action_feedback(get_blocked_action_feedback())
		print("Cannot interact with board outside preparation phase")
		return
	
	if grid_pos.y < 4:
		show_action_feedback("Deploy on your side")
		print("Enemy half - cannot place there")
		return
	
	if is_tile_occupied(grid_pos):
		show_action_feedback("Tile occupied")
		print("Tile occupied: ", grid_pos)
		return

	if selected_bench_index >= 0 and selected_bench_index < bench_units.size():
		try_deploy_bench_unit(grid_pos)
		return

	if selected_unit == null or not is_instance_valid(selected_unit):
		show_action_feedback("Select a unit")
		print("No selected unit")
		return

	place_unit_on_grid(selected_unit, grid_pos)
	print("Moved selected unit to: ", grid_pos)
	clear_unit_selection()

func try_deploy_bench_unit(grid_pos: Vector2i) -> bool:
	print("TRY DEPLOY BENCH UNIT: index ", selected_bench_index, " tile ", grid_pos)
	if not is_preparation_phase():
		show_action_feedback(get_blocked_action_feedback())
		print("Cannot deploy bench unit outside preparation phase")
		return false

	if selected_bench_index < 0 or selected_bench_index >= bench_units.size():
		show_action_feedback("Select a bench unit")
		print("No bench unit selected")
		return false

	if grid_pos.y < 4:
		show_action_feedback("Deploy on your side")
		print("Cannot deploy to enemy half")
		return false

	if is_tile_occupied(grid_pos):
		show_action_feedback("Tile occupied")
		print("Cannot deploy to occupied tile: ", grid_pos)
		return false

	if player_roster.size() >= max_player_units:
		show_action_feedback("Unit cap reached")
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
	print("Deployed ", data.get("name", unit_id), " from bench at ", grid_pos, " star: ", star_level)
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
		show_action_feedback("Run ended")
		print("Cannot start battle after run has ended")
		return
	start_battle()

func generate_battle_seed() -> int:
	return randi()

func create_battle_payload() -> Dictionary:
	var opponent_source = "snapshot" if use_snapshot_opponent else "pve_wave"
	var opponent_snapshot = opponent_army_snapshot if use_snapshot_opponent else create_spawned_opponent_army_snapshot()
	return battle_snapshot.create_battle_payload({
		"battle_id": current_battle_id,
		"battle_seed": current_battle_seed,
		"round_number": round_number,
		"player_level": player_level,
		"player_health": player_health,
		"player_gold": player_gold,
		"player_army_snapshot": create_player_army_snapshot(),
		"opponent_source": opponent_source,
		"opponent_army_snapshot": opponent_snapshot
	})

func start_battle() -> void:
	if not is_preparation_phase():
		show_action_feedback(get_blocked_action_feedback())
		return
	
	current_battle_id += 1
	current_battle_seed = generate_battle_seed()
	current_battle_payload = create_battle_payload()
	battle_started = true
	round_ended = false
	round_result_label.text = ""
	restart_button.visible = false
	
	clear_all_selection()
	
	print("Battle ", current_battle_id, " seed: ", current_battle_seed)
	print("Battle payload created")
	add_event_log("Battle started")
	play_audio_event("start_battle")
	
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

func create_battle_summary(result_text: String, player_damage_taken: int = 0) -> Dictionary:
	var opponent_source = "snapshot" if use_snapshot_opponent else "pve_wave"
	var opponent_snapshot = opponent_army_snapshot if use_snapshot_opponent else create_spawned_opponent_army_snapshot()
	return battle_snapshot.create_battle_summary({
		"battle_id": current_battle_id,
		"battle_seed": current_battle_seed,
		"round_number": round_number,
		"result": result_text,
		"player_health": player_health,
		"player_level": player_level,
		"player_gold": player_gold,
		"player_army_snapshot": create_player_army_snapshot(),
		"opponent_source": opponent_source,
		"opponent_army_snapshot": opponent_snapshot,
		"surviving_units": create_surviving_units_snapshot(),
		"player_damage_taken": player_damage_taken
	})

func create_surviving_units_snapshot() -> Array[Dictionary]:
	var units := get_tree().get_nodes_in_group("units")
	return battle_snapshot.create_surviving_units_snapshot(units)

func get_round_loss_damage(target_round: int) -> int:
	return economy_rules.get_round_loss_damage(target_round)

func get_surviving_opponent_unit_damage() -> int:
	var damage := 0
	var units := get_tree().get_nodes_in_group("units")
	for unit in units:
		if is_instance_valid(unit) and unit.team_id == 1 and unit.current_hp > 0:
			damage += 1
	return damage

func calculate_player_loss_damage() -> int:
	return get_round_loss_damage(round_number) + get_surviving_opponent_unit_damage()

func record_battle_summary(summary: Dictionary) -> void:
	battle_history.append(summary)
	while battle_history.size() > max_battle_history_entries:
		battle_history.remove_at(0)

func export_last_battle_summary() -> void:
	if not export_battle_summaries:
		return
	if last_battle_summary.is_empty():
		return

	var error := DirAccess.make_dir_recursive_absolute(battle_summary_export_dir)
	if error != OK:
		print("Failed to create battle summary export dir: ", battle_summary_export_dir, " error: ", error)
		return

	var battle_id = last_battle_summary.get("battle_id", 0)
	var summary_round = last_battle_summary.get("round_number", round_number)
	var file_path = "%s/battle_%d_round_%d.json" % [battle_summary_export_dir, battle_id, summary_round]
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		print("Failed to export battle summary: ", file_path, " error: ", FileAccess.get_open_error())
		return

	file.store_string(JSON.stringify(last_battle_summary, "\t"))
	file.close()
	print("Exported battle summary to ", file_path)

func get_battle_history_summary_text() -> String:
	if battle_history.is_empty():
		return "Battle History: None"

	var lines := PackedStringArray()
	lines.append("Battle History:")
	for summary in battle_history:
		lines.append("#%d R%d %s" % [
			summary.get("battle_id", 0),
			summary.get("round_number", 0),
			summary.get("result", "")
		])
	return "\n".join(lines)

func end_round(result_text: String) -> void:
	var player_damage_taken := 0
	if result_text == "ENEMY WINS":
		player_damage_taken = calculate_player_loss_damage()
	
	last_battle_summary = create_battle_summary(result_text, player_damage_taken)
	record_battle_summary(last_battle_summary)
	export_last_battle_summary()
	print("Battle summary recorded")
	update_streaks_for_result(result_text)

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
		player_health = max(player_health - player_damage_taken, 0)
		update_player_health_label()
		print("Player took ", player_damage_taken, " damage. HP: ", player_health)
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

func calculate_interest_gold() -> int:
	return economy_rules.calculate_interest_gold(player_gold, interest_cap)

func update_streaks_for_result(result_text: String) -> void:
	if result_text == "PLAYER WINS":
		win_streak += 1
		loss_streak = 0
	elif result_text == "ENEMY WINS":
		loss_streak += 1
		win_streak = 0
	elif result_text == "DRAW":
		win_streak = 0
		loss_streak = 0

func calculate_streak_bonus() -> int:
	var current_streak = max(win_streak, loss_streak)
	return economy_rules.calculate_streak_bonus(current_streak, max_streak_bonus)

func restart_round() -> void:
	if game_over or victory:
		show_action_feedback("Run ended")
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
	
	var result_bonus := 0
	if last_round_result == "PLAYER WINS":
		result_bonus = win_bonus_gold
	elif last_round_result == "DRAW":
		result_bonus = draw_bonus_gold
	
	var interest := calculate_interest_gold()
	var streak_bonus := calculate_streak_bonus()
	player_gold += round_income + result_bonus + interest + streak_bonus
	print("Round income: ", round_income, " + bonus: ", result_bonus, " + interest: ", interest, " + streak: ", streak_bonus)
	add_event_log("Next round: +%dg income, +%dg bonus, +%dg interest, +%dg streak" % [round_income, result_bonus, interest, streak_bonus])
	grant_random_item()
	
	last_round_result = ""
	
	update_gold_label()
	update_round_label()
	update_unit_cap_label()
	update_synergy_label()
	roll_shop_offers()
	populate_shop()
	spawn_player_roster()
	spawn_opponent_army(round_number)

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
	return economy_rules.get_xp_required_for_level(player_level)

func update_max_player_units() -> void:
	max_player_units = economy_rules.get_max_player_units_for_level(player_level)

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
	play_audio_event("game_over")

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
	play_audio_event("victory")

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
	win_streak = 0
	loss_streak = 0
	player_level = 1
	player_xp = 0
	current_battle_id = 0
	current_battle_seed = 0
	current_battle_payload.clear()
	reset_battle_speed()
	reset_camera_zoom()
	update_max_player_units()
	event_log.clear()
	last_battle_summary.clear()
	battle_history.clear()
	use_snapshot_opponent = false
	opponent_army_snapshot.clear()
	item_inventory.clear()
	
	# Clear rosters and bench
	player_roster.clear()
	bench_units.clear()
	roster_id_counter = 0
	selected_bench_index = -1
	
	# Clear selection state
	clear_all_selection()
	clear_action_feedback()
	
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
	update_item_ui()
	update_mute_button_text()
	
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
		card.custom_minimum_size = Vector2(180, 80)
		
		if i in sold_shop_offer_indices:
			card.text = "SOLD\nRecruit gone"
			card.disabled = true
			style_sold_card_button(card)
		else:
			var can_afford = player_gold >= data["base_price"]
			card.text = "%s\n%s  %s  T%d\n%dg Recruit" % [
				data["name"],
				data["faction"],
				data["role"],
				data.get("tier", 1),
				data["base_price"]
			]
			card.disabled = not can_afford
			style_unit_card_button(card, data.get("faction", ""), not can_afford)
			card.pressed.connect(_on_shop_card_pressed.bind(unit_id, i))
		
		shop_items.add_child(card)

func clear_shop() -> void:
	for child in shop_items.get_children():
		child.queue_free()

func _on_buy_xp_button_pressed() -> void:
	if not is_preparation_phase():
		show_action_feedback(get_blocked_action_feedback())
		print("Cannot buy XP outside preparation phase")
		return

	if player_level >= max_player_level:
		show_action_feedback("Max level")
		print("Player is already at max level")
		return

	if player_gold < xp_purchase_cost:
		show_action_feedback("Not enough gold")
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
		show_action_feedback(get_blocked_action_feedback())
		print("Cannot buy outside preparation phase")
		return
	
	var data: Dictionary = unit_database.get_unit_data(unit_id)
	
	if data.is_empty():
		return
	
	var cost = data["base_price"]
	if offer_index in sold_shop_offer_indices:
		show_action_feedback("Already sold")
		print("Shop slot ", offer_index, " is already sold")
		return
	if player_gold < cost:
		show_action_feedback("Not enough gold")
		print("Cannot afford ", data["name"], ". Need ", cost, " gold, have ", player_gold)
		return

	if bench_units.size() >= max_bench_units:
		show_action_feedback("Bench full")
		print("Bench is full")
		return
	
	player_gold -= cost
	bench_units.append({"unit_id": unit_id, "star_level": 1})
	sold_shop_offer_indices.append(offer_index)
	update_gold_label()
	try_merge_bench_units()
	update_bench_ui()
	populate_shop()
	clear_all_selection()
	play_audio_event("buy")
	print("Bought ", data["name"], " to bench for ", cost, " gold")

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
				play_audio_event("merge")
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
		play_audio_event("merge")
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
		show_action_feedback(get_blocked_action_feedback())
		print("Cannot reroll outside preparation phase")
		return
	
	if player_gold < reroll_cost:
		show_action_feedback("Not enough gold")
		print("Cannot afford reroll. Need ", reroll_cost, " gold, have ", player_gold)
		return
	
	clear_shop_selection()
	player_gold -= reroll_cost
	update_gold_label()
	roll_shop_offers()
	populate_shop()
	play_audio_event("reroll")
	print("Rerolled shop for ", reroll_cost, " gold")

func get_item_data(item_id: String) -> Dictionary:
	return item_database.get_item_data(item_id)

func get_item_name(item_id: String) -> String:
	return item_database.get_item_name(item_id)

func grant_random_item() -> void:
	var item_ids = item_database.get_all_item_ids()
	if item_ids.is_empty():
		return

	var item_id = item_ids[randi_range(0, item_ids.size() - 1)]
	item_inventory.append(item_id)
	selected_item_index = -1
	update_item_ui()
	print("Granted item: ", get_item_name(item_id))

func update_item_ui() -> void:
	item_label.text = "Items: %d" % item_inventory.size()
	for child in item_items.get_children():
		child.queue_free()

	for i in range(item_inventory.size()):
		var item_id = item_inventory[i]
		var button := Button.new()
		button.custom_minimum_size = Vector2(95, 36)
		button.text = get_item_name(item_id)
		style_button(button)
		button.pressed.connect(_on_item_pressed.bind(i))
		item_items.add_child(button)

func _on_item_pressed(index: int) -> void:
	if not is_preparation_phase():
		show_action_feedback(get_blocked_action_feedback())
		print("Cannot select item outside preparation phase")
		return

	if index < 0 or index >= item_inventory.size():
		show_action_feedback("Item unavailable")
		print("Item index out of range: ", index)
		return

	clear_shop_selection()
	clear_bench_selection()
	clear_unit_selection()
	selected_item_index = index
	show_action_feedback("Selected item: %s" % get_item_name(item_inventory[index]))
	print("SELECTED ITEM: ", get_item_name(item_inventory[index]))

func equip_selected_item_to_unit(unit: CharacterBody3D) -> bool:
	if selected_item_index < 0 or selected_item_index >= item_inventory.size():
		return false

	if unit == null or not is_instance_valid(unit) or unit.team_id != 0:
		show_action_feedback("Select a player unit")
		return false

	if not unit.has_meta("roster_id"):
		show_action_feedback("No roster entry")
		print("Selected unit has no roster entry for item equip")
		return false

	var roster_id = unit.get_meta("roster_id")
	var roster_index = -1
	for i in range(player_roster.size()):
		if player_roster[i].get("roster_id", -1) == roster_id:
			roster_index = i
			break

	if roster_index < 0:
		show_action_feedback("No roster entry")
		print("Selected unit has no roster entry for item equip")
		return false

	var existing_items = player_roster[roster_index].get("item_ids", [])
	if not existing_items.is_empty():
		show_action_feedback("Unit already has item")
		print("Unit already has item: ", existing_items)
		return false

	var item_id = item_inventory[selected_item_index]
	item_inventory.remove_at(selected_item_index)
	player_roster[roster_index]["item_ids"] = [item_id]
	selected_item_index = -1
	refresh_player_unit_bonuses()
	update_item_ui()
	update_unit_details_panel()
	show_action_feedback("Equipped: %s" % get_item_name(item_id))
	print("Equipped ", get_item_name(item_id), " to ", unit.unit_name)
	return true

func _on_use_self_as_opponent_button_pressed() -> void:
	if not is_preparation_phase():
		show_action_feedback(get_blocked_action_feedback())
		print("Cannot mirror army outside preparation phase")
		return

	var snapshot = create_player_army_snapshot()
	if snapshot.is_empty():
		show_action_feedback("No army to mirror")
		print("No player army to mirror")
		return

	opponent_army_snapshot = snapshot
	use_snapshot_opponent = true
	clear_opponent_units()
	spawn_opponent_army(round_number)
	print("Using mirrored army as opponent")

func _on_sell_unit_button_pressed() -> void:
	if not is_preparation_phase():
		show_action_feedback(get_blocked_action_feedback())
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
		play_audio_event("sell")
		print("Sold bench ", bench_data["name"], " star: ", bench_star, " for ", bench_refund, " gold")
		return
	
	if selected_unit == null or not is_instance_valid(selected_unit):
		show_action_feedback("Select a unit")
		print("No unit selected to sell")
		return
	
	if selected_unit.team_id != 0:
		show_action_feedback("Cannot sell enemy")
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
	for item_id in roster_entry.get("item_ids", []):
		item_inventory.append(item_id)
	
	player_gold += deployed_refund
	player_roster.remove_at(roster_index)
	selected_unit.queue_free()
	clear_all_selection()
	refresh_player_unit_bonuses()
	
	update_gold_label()
	update_unit_cap_label()
	update_item_ui()
	populate_shop()
	play_audio_event("sell")
	print("Sold ", deployed_data["name"], " star: ", deployed_star, " for ", deployed_refund, " gold")

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
	synergy_label.text = synergy_rules.get_synergy_summary_text(faction_counts, role_counts)

func update_bench_ui() -> void:
	bench_label.text = "Bench: %d / %d" % [bench_units.size(), max_bench_units]
	for child in bench_items.get_children():
		child.queue_free()

	for i in range(bench_units.size()):
		var entry = bench_units[i]
		var button = Button.new()
		button.custom_minimum_size = Vector2(140, 36)
		button.text = get_bench_unit_display_name(entry)
		var unit_id = entry.get("unit_id", "")
		var data: Dictionary = unit_database.get_unit_data(unit_id)
		style_bench_slot_button(button, data.get("faction", ""))
		button.pressed.connect(_on_bench_unit_pressed.bind(i))
		bench_items.add_child(button)

func get_bench_unit_display_name(entry: Dictionary) -> String:
	var unit_id = entry.get("unit_id", "")
	var data: Dictionary = unit_database.get_unit_data(unit_id)
	var star_level = entry.get("star_level", 1)
	var unit_display_name = data.get("name", unit_id)
	return "%s  %s\n%s  %s  T%d" % [
		"★".repeat(clamp(star_level, 1, 3)),
		unit_display_name,
		data.get("faction", ""),
		data.get("role", ""),
		data.get("tier", 1)
	]

func _on_bench_unit_pressed(index: int) -> void:
	if not is_preparation_phase():
		show_action_feedback(get_blocked_action_feedback())
		print("Cannot select bench unit outside preparation phase")
		return

	if index < 0 or index >= bench_units.size():
		show_action_feedback("Bench slot empty")
		print("Bench index out of range: ", index)
		return

	selected_bench_index = index
	clear_shop_selection()
	clear_unit_selection()
	if board != null and board.has_method("highlight_tiles"):
		board.highlight_tiles(get_valid_player_empty_tiles())
	var unit_id = bench_units[index].get("unit_id", "")
	var data: Dictionary = unit_database.get_unit_data(unit_id)
	print("SELECTED BENCH UNIT: ", data.get("name", unit_id), " index: ", selected_bench_index)
