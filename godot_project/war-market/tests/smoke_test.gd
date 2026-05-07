extends SceneTree

var current_test_name: String = ""

func assert_true(condition: bool, message: String) -> void:
	if not condition:
		print("FAIL ", current_test_name, ": ", message)
		quit(1)
		return

func assert_eq(actual, expected, message: String) -> void:
	if actual != expected:
		print("FAIL ", current_test_name, ": ", message, " | actual=", str(actual), " expected=", str(expected))
		quit(1)
		return

func run_test(test_name: String, test_function: Callable) -> void:
	current_test_name = test_name
	print("RUNNING ", test_name)
	await test_function.call()
	print("PASS ", test_name)
	current_test_name = ""

func _init() -> void:
	print("Starting smoke test...")
	await run_test("Initial state", Callable(self, "test_initial_state"))
	await run_test("Battle speed toggle", Callable(self, "test_battle_speed_toggle"))
	await run_test("Mute toggle", Callable(self, "test_mute_toggle"))
	await run_test("Event log", Callable(self, "test_event_log"))
	await run_test("Action feedback", Callable(self, "test_action_feedback"))
	await run_test("Items", Callable(self, "test_items"))
	await run_test("Buy XP", Callable(self, "test_buy_xp"))
	await run_test("Shop tier rolls", Callable(self, "test_shop_tier_rolls"))
	await run_test("Faction bonuses", Callable(self, "test_faction_bonuses"))
	await run_test("Role bonuses", Callable(self, "test_role_bonuses"))
	await run_test("Unit details panel", Callable(self, "test_unit_details_panel"))
	await run_test("Board tile highlights", Callable(self, "test_board_tile_highlights"))
	await run_test("Reroll", Callable(self, "test_reroll"))
	await run_test("Buy to bench", Callable(self, "test_buy_to_bench"))
	await run_test("Sold slot", Callable(self, "test_sold_slot"))
	await run_test("Bench sell", Callable(self, "test_bench_sell"))
	await run_test("Bench merge to 2-star", Callable(self, "test_bench_merge_to_two_star"))
	await run_test("Bench merge to 3-star", Callable(self, "test_bench_merge_to_three_star"))
	await run_test("2-star deployed unit", Callable(self, "test_two_star_deployed_unit"))
	await run_test("Deployed merge to 2-star", Callable(self, "test_deployed_merge_to_two_star"))
	await run_test("Deployed merge to 3-star", Callable(self, "test_deployed_merge_to_three_star"))
	await run_test("Bench deploy", Callable(self, "test_bench_deploy"))
	await run_test("Bench deploy via board click", Callable(self, "test_bench_deploy_via_board_click"))
	await run_test("Invalid bench deploy", Callable(self, "test_invalid_bench_deploy"))
	await run_test("Unit cap", Callable(self, "test_unit_cap"))
	await run_test("Deployed sell", Callable(self, "test_deployed_sell"))
	await run_test("Player loss damage", Callable(self, "test_player_loss_damage"))
	await run_test("Game over after loss", Callable(self, "test_game_over_after_loss"))
	await run_test("Battle summary", Callable(self, "test_battle_summary"))
	await run_test("Victory after round 10", Callable(self, "test_victory_after_round_ten"))
	await run_test("Reset game new run", Callable(self, "test_reset_game_new_run"))
	await run_test("Enemy wave spawning", Callable(self, "test_enemy_wave_spawning"))
	await run_test("Opponent army snapshot", Callable(self, "test_opponent_army_snapshot"))
	await run_test("Mirror army button", Callable(self, "test_mirror_army_button"))
	await run_test("Interest gold", Callable(self, "test_interest_gold"))
	await run_test("Streak bonuses", Callable(self, "test_streak_bonuses"))
	await run_test("Next round bonus", Callable(self, "test_next_round_bonus"))

	print("SMOKE TEST PASSED")
	quit(0)

func load_game() -> Node:
	for child in root.get_children():
		child.queue_free()
	var main_scene = load("res://scenes/Main.tscn")
	var main = main_scene.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	return main

func test_initial_state() -> void:
	var game = await load_game()
	assert_eq(game.player_gold, game.starting_gold, "Initial gold should equal starting gold")
	assert_eq(game.player_health, game.starting_player_health, "Initial player health should equal starting health")
	assert_eq(game.round_number, 1, "Round should start at 1")
	assert_eq(game.current_shop_offers.size(), game.shop_offer_count, "Shop should show the configured number of offers")
	assert_valid_shop_offers(game)
	assert_eq(game.bench_units.size(), 0, "Bench should be empty at start")
	assert_eq(game.player_level, 1, "Player should start at level 1")
	assert_eq(game.player_xp, 0, "Player should start with 0 XP")
	assert_eq(game.max_player_units, 2, "Level 1 should allow 2 deployed units")
	assert_eq(game.win_streak, 0, "Win streak should start at 0")
	assert_eq(game.loss_streak, 0, "Loss streak should start at 0")
	assert_eq(game.player_level_label.text, "Level: 1 (0/2 XP)", "Player level label should show initial XP progress")
	assert_true(game.synergy_label != null, "SynergyLabel should exist")
	assert_true("Romans" in game.synergy_label.text, "Initial SynergyLabel should show active Roman synergy")
	assert_true(game.event_log_label != null, "EventLogLabel should exist")
	assert_true("New run started" in game.event_log_label.text, "Initial EventLogLabel should show new run started")
	assert_true(game.action_feedback_label != null, "ActionFeedbackLabel should exist")
	assert_true(not game.action_feedback_label.visible, "ActionFeedbackLabel should start hidden")
	assert_true(game.item_label != null, "ItemLabel should exist")
	assert_eq(game.item_inventory.size(), 0, "Item inventory should start empty")
	assert_eq(game.item_label.text, "Items: 0", "ItemLabel should show empty inventory")
	assert_true(game.audio_manager != null, "AudioManager should exist")
	assert_true(game.mute_button != null, "MuteButton should exist")
	assert_eq(game.mute_button.text, "Sound: On", "MuteButton should start with sound on")
	assert_eq(game.audio_manager.call("is_muted"), false, "AudioManager should start unmuted")

func test_battle_speed_toggle() -> void:
	var game = await load_game()
	assert_eq(game.battle_speed_index, 0, "Battle speed should start at index 0")
	assert_float_eq(Engine.time_scale, 1.0, "Initial battle speed should be 1x")
	assert_eq(game.battle_speed_button.text, "Speed: 1x", "Initial battle speed button text should show 1x")

	game._on_battle_speed_button_pressed()
	assert_eq(game.battle_speed_index, 1, "First speed press should select 2x")
	assert_float_eq(Engine.time_scale, 2.0, "First speed press should apply 2x")
	assert_eq(game.battle_speed_button.text, "Speed: 2x", "Battle speed button should show 2x")

	game._on_battle_speed_button_pressed()
	assert_eq(game.battle_speed_index, 2, "Second speed press should select 4x")
	assert_float_eq(Engine.time_scale, 4.0, "Second speed press should apply 4x")
	assert_eq(game.battle_speed_button.text, "Speed: 4x", "Battle speed button should show 4x")

	game._on_battle_speed_button_pressed()
	assert_eq(game.battle_speed_index, 0, "Third speed press should wrap to 1x")
	assert_float_eq(Engine.time_scale, 1.0, "Third speed press should apply 1x")
	assert_eq(game.battle_speed_button.text, "Speed: 1x", "Battle speed button should show 1x after wrap")

	game._on_battle_speed_button_pressed()
	game._on_battle_speed_button_pressed()
	assert_eq(game.battle_speed_index, 2, "Battle speed should be set to 4x before restart")
	game.restart_round()
	assert_eq(game.battle_speed_index, 0, "Restart round should reset battle speed index")
	assert_float_eq(Engine.time_scale, 1.0, "Restart round should reset battle speed to 1x")
	assert_true("1x" in game.battle_speed_button.text, "Restart round should show 1x speed")

func test_mute_toggle() -> void:
	var game = await load_game()
	assert_eq(game.audio_manager.call("is_muted"), false, "AudioManager should start unmuted")

	var muted = game.audio_manager.call("toggle_muted")
	game.update_mute_button_text()
	assert_eq(muted, true, "toggle_muted should return the new muted state")
	assert_eq(game.audio_manager.call("is_muted"), true, "AudioManager should be muted after toggle")
	assert_eq(game.mute_button.text, "Sound: Off", "MuteButton should show sound off")
	game.play_audio_event("buy")
	game.reset_game()
	assert_eq(game.audio_manager.call("is_muted"), true, "reset_game should keep session mute preference")
	assert_eq(game.mute_button.text, "Sound: Off", "MuteButton should keep showing sound off after reset")

	game._on_mute_button_pressed()
	assert_eq(game.audio_manager.call("is_muted"), false, "Mute button should unmute audio")
	assert_eq(game.mute_button.text, "Sound: On", "MuteButton should show sound on")

func test_event_log() -> void:
	var game = await load_game()
	game.event_log.clear()
	game.update_event_log_ui()
	assert_eq(game.event_log.size(), 0, "Event log should be clearable")

	game.add_event_log("First event")
	assert_eq(game.event_log.size(), 1, "Adding an event should store it")
	assert_true("First event" in game.event_log_label.text, "Event log label should show added event")

	for i in range(game.max_event_log_entries + 2):
		game.add_event_log("Recent event %d" % i)

	assert_eq(game.event_log.size(), game.max_event_log_entries, "Event log should trim to max entries")
	assert_true(not ("First event" in game.event_log), "Event log should remove old entries")
	var latest_event = "Recent event %d" % (game.max_event_log_entries + 1)
	assert_true(latest_event in game.event_log_label.text, "Event log label should show recent events")

	game.event_log.clear()
	game.update_event_log_ui()
	game.player_gold = 100
	game.sold_shop_offer_indices.clear()
	game._on_shop_card_pressed("roman_spearman", 0)
	assert_true(not event_log_contains_prefix(game, "Bought"), "Routine buys should not be required in event log")

	game.start_battle()
	assert_true("Battle started" in game.event_log_label.text, "Important battle start should appear in event log")
	game.end_round("PLAYER WINS")
	assert_true("Round result: PLAYER WINS" in game.event_log_label.text, "Important round result should appear in event log")

func test_action_feedback() -> void:
	var game = await load_game()
	game.show_action_feedback("Test message")
	assert_true(game.action_feedback_label.visible, "Action feedback should show when requested")
	assert_true("Test message" in game.action_feedback_label.text, "Action feedback should show the requested message")
	game.clear_action_feedback()
	assert_true(not game.action_feedback_label.visible or game.action_feedback_label.text == "", "Action feedback should clear")
	game.play_audio_event("buy")

func test_items() -> void:
	var game = await load_game()
	var inventory_before = game.item_inventory.size()
	game.grant_random_item()
	assert_eq(game.item_inventory.size(), inventory_before + 1, "Granting an item should add to inventory")
	assert_true("Items: %d" % game.item_inventory.size() in game.item_label.text, "Item UI should show inventory count")

	game.item_inventory.clear()
	game.item_inventory.append("training_sword")
	game.update_item_ui()
	var player_unit = find_deployed_player_unit()
	assert_true(player_unit != null, "No deployed player unit available for item test")
	var roster_id = player_unit.get_meta("roster_id")
	var roster_entry = find_roster_entry(game, roster_id)
	assert_true(roster_entry != null, "Roster entry should exist for item equip")
	var damage_before = player_unit.damage

	game._on_item_pressed(0)
	assert_eq(game.selected_item_index, 0, "Clicking an item should select it")
	game._on_unit_clicked(player_unit)
	assert_eq(game.item_inventory.size(), 0, "Equipping should remove item from inventory")
	assert_true(roster_entry.has("item_ids"), "Roster entry should support item_ids")
	assert_eq(roster_entry.get("item_ids", []).size(), 1, "Equipped roster entry should have one item")
	assert_eq(roster_entry.get("item_ids", [])[0], "training_sword", "Roster should store equipped item id")
	assert_float_eq(player_unit.damage, damage_before + 10.0, "Training Sword should add damage after stat refresh")

	game.item_inventory.append("longbow")
	game.update_item_ui()
	game._on_item_pressed(0)
	game._on_unit_clicked(player_unit)
	assert_eq(game.item_inventory.size(), 1, "Unit with an item should not equip a second item")
	assert_true("Unit already has item" in game.action_feedback_label.text, "Equipping a second item should show feedback")

	game.selected_item_index = -1
	game.selected_unit = player_unit
	game._on_sell_unit_button_pressed()
	assert_true("training_sword" in game.item_inventory, "Selling deployed unit should return equipped item to inventory")

	game = await load_game()
	player_unit = find_deployed_player_unit()
	assert_true(player_unit != null, "No deployed player unit available for item persistence test")
	roster_id = player_unit.get_meta("roster_id")
	roster_entry = find_roster_entry(game, roster_id)
	var unit_id = roster_entry.get("unit_id", "")
	var base_hp = game.unit_database.get_unit_data(unit_id)["max_hp"]
	var expected_hp = base_hp
	var faction = game.unit_database.get_unit_data(unit_id).get("faction", "")
	if faction == "Romans":
		expected_hp *= 1.2
	if game.get_active_role_bonuses().has(game.unit_database.get_unit_data(unit_id).get("role", "")):
		expected_hp *= game.get_active_role_bonuses()[game.unit_database.get_unit_data(unit_id).get("role", "")].get("max_hp_multiplier", 1.0)
	expected_hp += 50.0

	game.item_inventory.append("wooden_shield")
	game.update_item_ui()
	game._on_item_pressed(0)
	game._on_unit_clicked(player_unit)
	assert_float_eq(player_unit.max_hp, expected_hp, "Wooden Shield should add max HP after synergies")
	game.restart_round()
	await process_frame
	var respawned_unit = find_player_unit_by_roster_id(roster_id)
	assert_true(respawned_unit != null, "Equipped unit should respawn after next round")
	roster_entry = find_roster_entry(game, roster_id)
	assert_eq(roster_entry.get("item_ids", [])[0], "wooden_shield", "Equipped item should persist in roster after restart_round")
	assert_float_eq(respawned_unit.max_hp, expected_hp, "Respawned unit should keep item stat bonus")

func test_buy_xp() -> void:
	var game = await load_game()
	var gold_before = game.player_gold
	game._on_buy_xp_button_pressed()
	assert_eq(game.player_gold, gold_before - game.xp_purchase_cost, "Buying XP should subtract XP purchase cost")
	assert_eq(game.player_level, 2, "Buying 4 XP at level 1 should level up to 2")
	assert_eq(game.player_xp, 2, "Remaining XP should carry toward the next level")
	assert_eq(game.max_player_units, 3, "Level 2 should increase deployed unit cap to 3")
	assert_eq(game.unit_cap_label.text, "Units: 2 / 3", "Unit cap label should update after leveling")

	game.player_gold = 0
	gold_before = game.player_gold
	var level_before = game.player_level
	var xp_before = game.player_xp
	game._on_buy_xp_button_pressed()
	assert_eq(game.player_gold, gold_before, "Buying XP without gold should not change gold")
	assert_eq(game.player_level, level_before, "Buying XP without gold should not change level")
	assert_eq(game.player_xp, xp_before, "Buying XP without gold should not change XP")

	game.player_gold = 100
	game.player_level = game.max_player_level
	game.player_xp = 0
	game.update_max_player_units()
	game.update_player_level_label()
	gold_before = game.player_gold
	game._on_buy_xp_button_pressed()
	assert_eq(game.player_gold, gold_before, "Buying XP at max level should not spend gold")
	assert_eq(game.player_level, game.max_player_level, "Buying XP at max level should not change level")
	assert_eq(game.player_xp, 0, "Buying XP at max level should not add XP")

func test_shop_tier_rolls() -> void:
	var game = await load_game()
	var tier_2_unit_ids: Array[String] = [
		"roman_centurion",
		"viking_raider",
		"mongol_horse_archer"
	]
	for unit_id in tier_2_unit_ids:
		var data: Dictionary = game.unit_database.get_unit_data(unit_id)
		assert_true(not data.is_empty(), unit_id + " should exist in UnitDatabase")
		assert_eq(data.get("tier", 0), 2, unit_id + " should be tier 2")
		assert_true(unit_id in game.shop_unit_ids, unit_id + " should be available in the shop pool")

	game.roll_shop_offers()
	assert_eq(game.current_shop_offers.size(), game.shop_offer_count, "Shop roll should produce the configured offer count")
	assert_valid_shop_offers(game)

	game.player_level = 6
	var found_tier_2_offer = false
	var original_level_6_odds = game.shop_tier_odds[6]
	game.shop_tier_odds[6] = {2: 100}
	for i in range(5):
		game.roll_shop_offers()
		assert_eq(game.current_shop_offers.size(), game.shop_offer_count, "Level 6 shop roll should produce the configured offer count")
		assert_valid_shop_offers(game)
		for unit_id in game.current_shop_offers:
			if game.unit_database.get_unit_data(unit_id).get("tier", 0) == 2:
				found_tier_2_offer = true
	game.shop_tier_odds[6] = original_level_6_odds
	assert_true(found_tier_2_offer, "At least one tier 2 unit should appear across level 6 shop rolls")

	game.shop_tier_odds[6] = {3: 100}
	game.roll_shop_offers()
	assert_eq(game.current_shop_offers.size(), game.shop_offer_count, "Shop roll should fall back when the rolled tier pool is empty")
	assert_valid_shop_offers(game)
	game.shop_tier_odds[6] = original_level_6_odds

func test_faction_bonuses() -> void:
	var game = await load_game()
	game.clear_units()
	await process_frame
	game.player_roster.clear()
	game.roster_id_counter = 0
	game.add_player_roster_unit("roman_legionary", Vector2i(2, 6))
	game.add_player_roster_unit("roman_spearman", Vector2i(3, 6))
	game.spawn_player_roster()
	game.refresh_player_unit_bonuses()

	var roman_unit = find_player_unit_by_roster_id(1)
	assert_true(roman_unit != null, "Roman unit should be spawned for faction bonus test")
	var roman_base_hp = game.unit_database.get_unit_data("roman_legionary")["max_hp"]
	assert_float_eq(roman_unit.max_hp, roman_base_hp * 1.2, "Roman synergy should increase Roman max HP")
	assert_true("Romans" in game.synergy_label.text, "SynergyLabel should mention Romans when Roman synergy is active")

	game.clear_units()
	await process_frame
	game.player_roster.clear()
	game.roster_id_counter = 0
	game.add_player_roster_unit("viking_berserker", Vector2i(2, 6))
	game.add_player_roster_unit("viking_axeman", Vector2i(3, 6))
	game.spawn_player_roster()
	game.refresh_player_unit_bonuses()

	var viking_unit = find_player_unit_by_roster_id(1)
	assert_true(viking_unit != null, "Viking unit should be spawned for faction bonus test")
	var viking_base_damage = game.unit_database.get_unit_data("viking_berserker")["damage"]
	assert_float_eq(viking_unit.damage, viking_base_damage * 1.2 * 1.15, "Viking damage should include faction and Fighter role synergy")

func test_role_bonuses() -> void:
	var game = await load_game()
	game.clear_units()
	await process_frame
	game.player_roster.clear()
	game.roster_id_counter = 0
	game.add_player_roster_unit("roman_legionary", Vector2i(2, 6))
	game.add_player_roster_unit("roman_centurion", Vector2i(3, 6))
	game.spawn_player_roster()
	game.refresh_player_unit_bonuses()

	var tank_unit = find_player_unit_by_roster_id(1)
	assert_true(tank_unit != null, "Tank unit should be spawned for role bonus test")
	var tank_base_hp = game.unit_database.get_unit_data("roman_legionary")["max_hp"]
	assert_float_eq(tank_unit.max_hp, tank_base_hp * 1.2 * 1.2, "Tank synergy should stack with Roman HP synergy")
	assert_true("Tank" in game.synergy_label.text, "SynergyLabel should mention Tank role synergy")

	game.clear_units()
	await process_frame
	game.player_roster.clear()
	game.roster_id_counter = 0
	game.add_player_roster_unit("roman_archer", Vector2i(2, 6))
	game.add_player_roster_unit("slav_hunter", Vector2i(3, 6))
	game.spawn_player_roster()
	game.refresh_player_unit_bonuses()

	var ranged_unit = find_player_unit_by_roster_id(1)
	assert_true(ranged_unit != null, "Ranged unit should be spawned for role bonus test")
	var ranged_base_range = game.unit_database.get_unit_data("roman_archer")["attack_range"]
	assert_float_eq(ranged_unit.attack_range, ranged_base_range * 1.1, "Ranged synergy should increase attack range")
	assert_true("Ranged" in game.synergy_label.text, "SynergyLabel should mention Ranged role synergy")

func test_unit_details_panel() -> void:
	var game = await load_game()
	var player_unit = find_deployed_player_unit()
	assert_true(player_unit != null, "No deployed player unit available for details panel test")
	game.select_unit(player_unit)
	game.update_unit_details_panel()
	assert_true(game.unit_details_panel.visible, "Unit details panel should show for selected deployed unit")
	assert_true(player_unit.unit_name in game.unit_details_label.text, "Unit details should include selected unit name")
	game.clear_unit_selection()
	assert_true(not game.unit_details_panel.visible, "Unit details panel should hide after clearing selection")

func test_board_tile_highlights() -> void:
	var game = await load_game()
	var valid_tiles = game.get_valid_player_empty_tiles()
	assert_true(valid_tiles.size() > 0, "There should be valid empty player-side tiles in preparation")
	for tile in valid_tiles:
		assert_true(tile.y >= 4, "Valid placement tiles should be on player side")
		assert_true(not game.is_tile_occupied(tile), "Valid placement tiles should be empty")

	game.bench_units.append({"unit_id": "roman_spearman", "star_level": 1})
	game.update_bench_ui()
	game._on_bench_unit_pressed(game.bench_units.size() - 1)
	assert_true(game.board.highlighted_tile_positions.size() == valid_tiles.size(), "Bench selection should highlight valid tiles")

	game.clear_all_selection()
	assert_eq(game.board.highlighted_tile_positions.size(), 0, "Clearing selection should remove highlights")

	var player_unit = find_deployed_player_unit()
	assert_true(player_unit != null, "No deployed player unit available for highlight test")
	game.select_unit(player_unit)
	assert_true(game.board.highlighted_tile_positions.size() == game.get_valid_player_empty_tiles().size(), "Deployed unit selection should highlight valid movement tiles")

	game.start_battle()
	assert_eq(game.board.highlighted_tile_positions.size(), 0, "Starting battle should clear tile highlights")

func test_reroll() -> void:
	var game = await load_game()
	var gold_before = game.player_gold
	game._on_reroll_button_pressed()
	assert_eq(game.player_gold, gold_before - game.reroll_cost, "Reroll should subtract reroll cost")
	assert_eq(game.current_shop_offers.size(), game.shop_offer_count, "Reroll should still show the configured number of offers")

func test_buy_to_bench() -> void:
	var game = await load_game()
	var offer_index = find_affordable_shop_offer(game)
	assert_true(offer_index >= 0, "No affordable shop offer found for buy test")
	var price = get_offer_price(game, offer_index)
	var gold_before = game.player_gold
	var bench_before = game.bench_units.size()
	game._on_shop_card_pressed(game.current_shop_offers[offer_index], offer_index)
	assert_eq(game.bench_units.size(), bench_before + 1, "Bench size should increase after buy")
	assert_eq(game.player_gold, gold_before - price, "Gold should decrease by the offer price")
	assert_true(offer_index in game.sold_shop_offer_indices, "Bought shop slot should be marked sold")
	assert_eq(game.current_shop_offers.size(), game.shop_offer_count, "Shop should keep the number of offer slots")

func test_sold_slot() -> void:
	var game = await load_game()
	var offer_index = find_affordable_shop_offer(game)
	assert_true(offer_index >= 0, "No affordable shop offer found for sold slot setup")
	game._on_shop_card_pressed(game.current_shop_offers[offer_index], offer_index)
	var bench_before = game.bench_units.size()
	var gold_before = game.player_gold
	var sold_index = game.sold_shop_offer_indices[game.sold_shop_offer_indices.size() - 1]
	var unit_id = game.current_shop_offers[sold_index]
	game._on_shop_card_pressed(unit_id, sold_index)
	assert_eq(game.bench_units.size(), bench_before, "Buying a sold slot should not increase bench size")
	assert_eq(game.player_gold, gold_before, "Buying a sold slot should not decrease gold")

func test_bench_sell() -> void:
	var game = await load_game()
	var offer_index = find_affordable_shop_offer(game)
	assert_true(offer_index >= 0, "No affordable shop offer found for bench sell setup")
	game._on_shop_card_pressed(game.current_shop_offers[offer_index], offer_index)
	var bench_before = game.bench_units.size()
	var gold_before = game.player_gold
	var unit_id = game.bench_units[0].get("unit_id", "")
	var price = game.unit_database.get_unit_data(unit_id)["base_price"]
	game.selected_bench_index = 0
	game._on_sell_unit_button_pressed()
	assert_eq(game.bench_units.size(), bench_before - 1, "Bench size should decrease after selling a bench unit")
	assert_eq(game.player_gold, gold_before + price, "Gold should refund the bench unit price")

func test_bench_merge_to_two_star() -> void:
	var game = await load_game()
	var unit_id = "roman_spearman"
	for i in range(3):
		game.bench_units.append({"unit_id": unit_id, "star_level": 1})
	game.try_merge_bench_units()
	assert_eq(game.bench_units.size(), 1, "Bench should merge three identical units into one entry")
	assert_eq(game.bench_units[0].get("unit_id", ""), unit_id, "Merged unit should preserve unit id")
	assert_eq(game.bench_units[0].get("star_level", 1), 2, "Merged unit should be 2-star")
	var gold_before = game.player_gold
	game.selected_bench_index = 0
	game._on_sell_unit_button_pressed()
	var base_price = game.unit_database.get_unit_data(unit_id)["base_price"]
	assert_eq(game.player_gold, gold_before + base_price * 3, "Selling a 2-star bench unit should refund 3x base price")

func test_bench_merge_to_three_star() -> void:
	var game = await load_game()
	var unit_id = "roman_spearman"
	for i in range(3):
		game.bench_units.append({"unit_id": unit_id, "star_level": 2})
	game.try_merge_bench_units()
	assert_eq(game.bench_units.size(), 1, "Bench should merge three identical 2-star units into one entry")
	assert_eq(game.bench_units[0].get("unit_id", ""), unit_id, "3-star merged unit should preserve unit id")
	assert_eq(game.bench_units[0].get("star_level", 1), 3, "Merged unit should be 3-star")
	assert_eq(game.get_bench_unit_display_name(game.bench_units[0]), "Roman Spearman ★★★\nTier 1", "Bench UI text should show stars and tier")
	var gold_before = game.player_gold
	game.selected_bench_index = 0
	game._on_sell_unit_button_pressed()
	var base_price = game.unit_database.get_unit_data(unit_id)["base_price"]
	assert_eq(game.player_gold, gold_before + base_price * 9, "Selling a 3-star bench unit should refund 9x base price")

func test_two_star_deployed_unit() -> void:
	var game = await load_game()
	buy_xp_for_extra_unit_cap(game)
	var unit_id = "roman_spearman"
	for i in range(3):
		game.bench_units.append({"unit_id": unit_id, "star_level": 1})
	game.try_merge_bench_units()
	assert_eq(game.bench_units.size(), 1, "Bench should have one merged unit")
	assert_eq(game.bench_units[0].get("star_level", 1), 2, "Merged unit should be 2-star")
	var tile = find_empty_player_tile(game)
	assert_true(tile != null, "No empty player tile available for 2-star deploy")
	game.selected_bench_index = 0
	var deployed = game.try_deploy_bench_unit(tile)
	assert_true(deployed, "Deploying a merged 2-star unit should succeed")
	var roster_id = game.player_roster[game.player_roster.size() - 1]["roster_id"]
	var deployed_unit = null
	for unit in get_nodes_in_group("units"):
		if unit.team_id == 0 and unit.has_meta("roster_id") and unit.get_meta("roster_id") == roster_id:
			deployed_unit = unit
			break
	assert_true(deployed_unit != null, "The newly deployed 2-star unit should exist")
	assert_eq(deployed_unit.star_level, 2, "Spawned deployed unit should carry 2-star level")

func test_deployed_merge_to_two_star() -> void:
	var game = await load_game()
	buy_xp_for_extra_unit_cap(game)
	var unit_id = "roman_spearman"
	game.bench_units.append({"unit_id": unit_id, "star_level": 1})
	var tile = find_empty_player_tile(game)
	assert_true(tile != null, "No empty player tile available for deployed merge setup")
	game.selected_bench_index = 0
	var deployed = game.try_deploy_bench_unit(tile)
	assert_true(deployed, "Deploying the first merge copy should succeed")

	var roster_id = game.player_roster[game.player_roster.size() - 1]["roster_id"]
	game.bench_units.append({"unit_id": unit_id, "star_level": 1})
	game.bench_units.append({"unit_id": unit_id, "star_level": 1})
	game.try_merge_bench_units()

	assert_eq(game.bench_units.size(), 0, "Deployed merge should remove the two matching bench copies")
	var roster_entry = find_roster_entry(game, roster_id)
	assert_true(roster_entry != null, "Merged roster entry should still exist")
	assert_eq(roster_entry.get("star_level", 1), 2, "Merged roster entry should be 2-star")
	var spawned_unit = find_player_unit_by_roster_id(roster_id)
	assert_true(spawned_unit != null, "Merged deployed unit should still be spawned")
	assert_eq(spawned_unit.star_level, 2, "Spawned deployed unit should update to 2-star")

	game.restart_round()
	await process_frame
	var respawned_unit = find_player_unit_by_roster_id(roster_id)
	assert_true(respawned_unit != null, "Merged roster unit should respawn after next round")
	assert_eq(respawned_unit.star_level, 2, "Respawned roster unit should remain 2-star")

func test_deployed_merge_to_three_star() -> void:
	var game = await load_game()
	buy_xp_for_extra_unit_cap(game)
	var unit_id = "roman_spearman"
	game.bench_units.append({"unit_id": unit_id, "star_level": 2})
	var tile = find_empty_player_tile(game)
	assert_true(tile != null, "No empty player tile available for deployed 3-star merge setup")
	game.selected_bench_index = 0
	var deployed = game.try_deploy_bench_unit(tile)
	assert_true(deployed, "Deploying the 2-star merge base should succeed")

	var roster_id = game.player_roster[game.player_roster.size() - 1]["roster_id"]
	game.bench_units.append({"unit_id": unit_id, "star_level": 2})
	game.bench_units.append({"unit_id": unit_id, "star_level": 2})
	game.try_merge_bench_units()

	assert_eq(game.bench_units.size(), 0, "3-star deployed merge should remove two matching 2-star bench copies")
	var roster_entry = find_roster_entry(game, roster_id)
	assert_true(roster_entry != null, "3-star merged roster entry should still exist")
	assert_eq(roster_entry.get("star_level", 1), 3, "Merged roster entry should be 3-star")
	var spawned_unit = find_player_unit_by_roster_id(roster_id)
	assert_true(spawned_unit != null, "3-star merged deployed unit should still be spawned")
	assert_eq(spawned_unit.star_level, 3, "Spawned deployed unit should update to 3-star")
	assert_eq(spawned_unit.star_label.text, "★★★", "Deployed StarLabel should show three stars")
	var base_hp = game.unit_database.get_unit_data(unit_id)["max_hp"]
	assert_float_eq(spawned_unit.max_hp, base_hp * 3.2 * 1.2, "3-star Roman unit should use star scaling plus Roman synergy")

	game.restart_round()
	await process_frame
	var respawned_unit = find_player_unit_by_roster_id(roster_id)
	assert_true(respawned_unit != null, "3-star roster unit should respawn after next round")
	assert_eq(respawned_unit.star_level, 3, "Respawned roster unit should remain 3-star")
	assert_eq(respawned_unit.star_label.text, "★★★", "Respawned StarLabel should show three stars")

func test_bench_deploy() -> void:
	var game = await load_game()
	buy_xp_for_extra_unit_cap(game)
	var offer_index = find_affordable_shop_offer(game)
	assert_true(offer_index >= 0, "No affordable shop offer found for bench deploy setup")
	game._on_shop_card_pressed(game.current_shop_offers[offer_index], offer_index)
	var bench_before = game.bench_units.size()
	var roster_before = game.player_roster.size()
	var tile = find_empty_player_tile(game)
	assert_true(tile != null, "No empty player tile available for bench deploy")
	game._on_bench_unit_pressed(game.bench_units.size() - 1)
	assert_eq(game.selected_bench_index, bench_before - 1, "Bench click should select the bench unit")
	game._on_board_tile_clicked(tile)
	assert_eq(game.bench_units.size(), bench_before - 1, "Bench size should decrease after deploy")
	assert_eq(game.player_roster.size(), roster_before + 1, "Roster size should increase after deploy")
	assert_true(has_player_unit_at_tile(tile), "A player unit should be spawned at the deployed tile")
	assert_eq(game.selected_bench_index, -1, "Bench selection should clear after deploy")

func test_bench_deploy_via_board_click() -> void:
	var game = await load_game()
	buy_xp_for_extra_unit_cap(game)
	game.bench_units.append({"unit_id": "roman_spearman", "star_level": 1})
	game.update_bench_ui()
	assert_eq(game.bench_units.size(), 1, "Bench setup should add one unit")

	var tile = find_empty_player_tile(game)
	assert_true(tile != null, "No empty player tile available for board-click bench deploy")
	var bench_before = game.bench_units.size()
	var roster_before = game.player_roster.size()

	game._on_bench_unit_pressed(0)
	assert_eq(game.selected_bench_index, 0, "Bench unit should be selected before board click")
	assert_true(game.board.highlighted_tile_positions.size() > 0, "Bench selection should highlight valid tiles")
	game._on_board_tile_clicked(tile)

	assert_eq(game.bench_units.size(), bench_before - 1, "Board click should remove deployed bench unit")
	assert_eq(game.player_roster.size(), roster_before + 1, "Board click should add the unit to player roster")
	assert_eq(game.selected_bench_index, -1, "Board click deploy should clear bench selection")
	assert_eq(game.board.highlighted_tile_positions.size(), 0, "Board click deploy should clear tile highlights")
	assert_true(has_player_unit_at_tile(tile), "Board click should spawn the bench unit on the clicked tile")
	game.board.clear_tile_highlights()

func test_invalid_bench_deploy() -> void:
	var game = await load_game()
	var offer_index = find_affordable_shop_offer(game)
	assert_true(offer_index >= 0, "No affordable shop offer found for invalid bench deploy setup")
	game._on_shop_card_pressed(game.current_shop_offers[offer_index], offer_index)
	var bench_before = game.bench_units.size()
	var roster_before = game.player_roster.size()
	var occupied_tile = find_occupied_player_tile(game)
	assert_true(occupied_tile != null, "No occupied player tile available for invalid bench deploy")
	game.selected_bench_index = game.bench_units.size() - 1
	var deployed = game.try_deploy_bench_unit(occupied_tile)
	assert_true(not deployed, "Bench deploy should fail on occupied tile")
	assert_eq(game.bench_units.size(), bench_before, "Bench size should remain unchanged after failed deploy")
	assert_eq(game.player_roster.size(), roster_before, "Roster should remain unchanged after failed deploy")

func test_unit_cap() -> void:
	var game = await load_game()
	game.player_gold = 100
	while game.player_roster.size() < min(game.max_player_units, game.current_shop_offers.size()):
		var offer_index = find_affordable_shop_offer(game)
		assert_true(offer_index >= 0, "No affordable shop offer available while filling unit cap")
		game._on_shop_card_pressed(game.current_shop_offers[offer_index], offer_index)
		var tile = find_empty_player_tile(game)
		assert_true(tile != null, "No empty tile available while filling cap")
		game.selected_bench_index = game.bench_units.size() - 1
		var deployed = game.try_deploy_bench_unit(tile)
		assert_true(deployed, "Bench deploy should succeed while filling to unit cap")

	while game.player_roster.size() < game.max_player_units:
		game.player_roster.append({"unit_id": "dummy", "roster_id": -1})

	if game.bench_units.size() == 0:
		assert_true(game.current_shop_offers.size() > 0, "No shop offers available to add a bench unit for cap overflow test")
		game.bench_units.append({"unit_id": game.current_shop_offers[0]})

	var bench_before = game.bench_units.size()
	var roster_before = game.player_roster.size()
	var tile = find_empty_player_tile(game)
	assert_true(tile != null, "No empty tile available for cap overflow test")
	game.selected_bench_index = game.bench_units.size() - 1
	var deployed = game.try_deploy_bench_unit(tile)
	assert_true(not deployed, "Deploy should fail when player unit cap is reached")
	assert_eq(game.bench_units.size(), bench_before, "Bench should remain unchanged when deploy fails due to cap")
	assert_eq(game.player_roster.size(), roster_before, "Roster should remain unchanged when deploy fails due to cap")

func test_deployed_sell() -> void:
	var game = await load_game()
	var player_unit = find_deployed_player_unit()
	assert_true(player_unit != null, "No deployed player unit available to sell")
	var roster_before = game.player_roster.size()
	var gold_before = game.player_gold
	var unit_id = player_unit.name
	if player_unit.has_meta("roster_id"):
		var roster_id = player_unit.get_meta("roster_id")
		for entry in game.player_roster:
			if entry["roster_id"] == roster_id:
				unit_id = entry["unit_id"]
				break
	var price = game.unit_database.get_unit_data(unit_id)["base_price"]
	game.selected_unit = player_unit
	game._on_sell_unit_button_pressed()
	assert_eq(game.player_roster.size(), roster_before - 1, "Player roster should decrease after selling deployed unit")
	assert_eq(game.player_gold, gold_before + price, "Gold should refund the deployed unit price")

func test_game_over_after_loss() -> void:
	var game = await load_game()
	game.player_health = game.calculate_player_loss_damage()
	game.end_round("ENEMY WINS")
	assert_eq(game.player_health, 0, "Player health should be clamped to zero after loss")
	assert_true(game.game_over, "Game over should be true after health reaches zero")
	assert_eq(game.round_result_label.text, "GAME OVER", "Round result label should show GAME OVER")

func test_player_loss_damage() -> void:
	var game = await load_game()
	assert_eq(game.get_round_loss_damage(1), 2, "Round 1 loss damage should be 2")
	assert_eq(game.get_round_loss_damage(3), 3, "Round 3 loss damage should be 3")
	assert_eq(game.get_round_loss_damage(5), 4, "Round 5 loss damage should be 4")
	assert_eq(game.get_round_loss_damage(7), 5, "Round 7 loss damage should be 5")
	assert_eq(game.get_round_loss_damage(9), 6, "Round 9 loss damage should be 6")

	for unit in get_nodes_in_group("units"):
		if unit.team_id == 1:
			unit.queue_free()
	await process_frame

	game.spawn_unit_by_id("viking_berserker", 1, Vector2i(5, 1))
	game.spawn_unit_by_id("viking_axeman", 1, Vector2i(6, 1))
	await process_frame

	game.round_number = 3
	game.player_health = 20
	var expected_damage = game.get_round_loss_damage(game.round_number) + 2
	game.end_round("ENEMY WINS")
	assert_eq(game.player_health, 20 - expected_damage, "Loss should damage player by round damage plus surviving opponents")
	assert_eq(game.last_battle_summary["player_damage_taken"], expected_damage, "Battle summary should record player damage taken")

	game = await load_game()
	var health_before = game.player_health
	game.end_round("PLAYER WINS")
	assert_eq(game.player_health, health_before, "Winning should not damage player health")
	assert_eq(game.last_battle_summary["player_damage_taken"], 0, "Winning summary should record no player damage")

func test_battle_summary() -> void:
	var game = await load_game()
	var battle_id_before = game.current_battle_id
	game.start_battle()
	assert_eq(game.current_battle_id, battle_id_before + 1, "Starting battle should increment battle id")
	assert_true(game.current_battle_seed != 0, "Starting battle should generate a battle seed")
	assert_true(not game.current_battle_payload.is_empty(), "Starting battle should create a battle payload")
	assert_eq(game.current_battle_payload["battle_id"], game.current_battle_id, "Battle payload should record battle id")
	assert_eq(game.current_battle_payload["battle_seed"], game.current_battle_seed, "Battle payload should record battle seed")
	assert_true(game.current_battle_payload.has("player_army_snapshot"), "Battle payload should include player army snapshot")
	assert_true(game.current_battle_payload.has("opponent_army_snapshot"), "Battle payload should include opponent army snapshot")
	game.end_round("PLAYER WINS")
	var summary = game.last_battle_summary
	assert_true(not summary.is_empty(), "Battle summary should be recorded after round end")
	assert_eq(summary["result"], "PLAYER WINS", "Battle summary should record result")
	assert_eq(summary["battle_id"], game.current_battle_id, "Battle summary should record battle id")
	assert_eq(summary["battle_seed"], game.current_battle_seed, "Battle summary should record battle seed")
	assert_true(summary.has("player_army_snapshot"), "Battle summary should include player army snapshot")
	assert_true(summary.has("opponent_source"), "Battle summary should include opponent source")
	assert_true(typeof(summary["surviving_units"]) == TYPE_ARRAY, "Battle summary surviving units should be an array")
	assert_eq(game.battle_history.size(), 1, "Battle history should record one summary")
	assert_eq(game.battle_history[0]["result"], "PLAYER WINS", "Battle history should store the battle result")
	assert_true("#1 R1 PLAYER WINS" in game.get_battle_history_summary_text(), "Battle history text should summarize the result")

	game.reset_game()
	assert_eq(game.battle_history.size(), 0, "Battle history should clear on reset")

func test_victory_after_round_ten() -> void:
	var game = await load_game()
	game.round_number = game.max_rounds
	game.end_round("PLAYER WINS")
	assert_true(game.victory, "Victory should be true after winning max round")
	assert_eq(game.round_result_label.text, "VICTORY", "Round result label should show VICTORY")
	assert_true(not game.is_preparation_phase(), "Preparation phase should be blocked during victory")
	assert_true(game.restart_button.visible, "Restart button should be visible after victory")
	assert_eq(game.restart_button.text, "New Run", "Restart button should offer new run after victory")
	assert_true("VICTORY" in game.event_log_label.text, "Event log should mention victory")

	game.reset_game()
	assert_true(not game.victory, "Victory should reset for new run")
	assert_eq(game.round_number, 1, "Round number should reset to 1 after victory reset")

func test_reset_game_new_run() -> void:
	var game = await load_game()
	# Force game over
	game.player_health = game.calculate_player_loss_damage()
	game.end_round("ENEMY WINS")
	assert_true(game.game_over, "Game should be over before reset")
	
	# Store initial values for comparison
	var initial_gold = game.starting_gold
	var initial_health = game.starting_player_health
	var initial_round = 1
	var initial_bench_size = 0
	
	# Call reset_game via the restart button (which should detect game_over state)
	game._on_restart_round_button_pressed()
	await process_frame
	await process_frame
	
	# Verify game state is reset
	assert_true(not game.game_over, "Game over should be false after reset")
	assert_eq(game.player_health, initial_health, "Player health should be restored to starting health")
	assert_eq(game.player_gold, initial_gold, "Player gold should be reset to starting gold")
	assert_eq(game.round_number, initial_round, "Round number should be reset to 1")
	assert_eq(game.bench_units.size(), initial_bench_size, "Bench should be empty after reset")
	assert_eq(game.player_level, 1, "Player level should reset to 1 after new run")
	assert_eq(game.player_xp, 0, "Player XP should reset after new run")
	assert_eq(game.max_player_units, 2, "Unit cap should reset from level after new run")
	assert_eq(game.current_shop_offers.size(), game.shop_offer_count, "Fresh shop offers should be rolled")
	assert_eq(game.sold_shop_offer_indices.size(), 0, "Sold shop slots should be cleared")
	assert_true(game.player_roster.size() > 0, "Starting units should be spawned")
	assert_true(not game.restart_button.visible, "Restart button should be hidden after reset")

func test_enemy_wave_spawning() -> void:
	var game = await load_game()
	
	# Clear existing enemy units from initial setup
	for unit in get_nodes_in_group("units"):
		if unit.team_id == 1:
			unit.queue_free()
	await process_frame
	
	# Spawn round 5 enemies (which should have 5 units)
	game.spawn_enemy_wave(5)
	await process_frame
	
	# Count enemy units
	var enemy_count = 0
	for unit in get_nodes_in_group("units"):
		if unit.team_id == 1:
			enemy_count += 1
	
	assert_eq(enemy_count, 5, "Round 5 should spawn exactly 5 enemy units")

func test_opponent_army_snapshot() -> void:
	var game = await load_game()
	var snapshot = game.create_player_army_snapshot()
	assert_true(snapshot.size() > 0, "Player army snapshot should include deployed roster units")
	var first_entry = snapshot[0]
	assert_true(first_entry.has("unit_id"), "Snapshot entries should include unit_id")
	assert_true(first_entry.has("grid_pos"), "Snapshot entries should include grid_pos")
	assert_true(first_entry.has("star_level"), "Snapshot entries should include star_level")
	assert_true(not first_entry.has("roster_id"), "Snapshot entries should omit roster_id")

	for unit in get_nodes_in_group("units"):
		if unit.team_id == 1:
			unit.queue_free()
	await process_frame

	game.opponent_army_snapshot = snapshot
	game.use_snapshot_opponent = true
	game.spawn_opponent_army(game.round_number)
	await process_frame

	var opponent_count = 0
	var mirrored_first_pos = game.mirror_grid_pos_for_opponent(first_entry["grid_pos"])
	var found_mirrored_first = false
	for unit in get_nodes_in_group("units"):
		if unit.team_id != 1:
			continue
		opponent_count += 1
		if unit.grid_position == mirrored_first_pos:
			found_mirrored_first = true
			assert_eq(unit.get_meta("star_level"), first_entry["star_level"], "Snapshot opponent should preserve star level")

	assert_eq(opponent_count, snapshot.size(), "Snapshot opponent should spawn one enemy per snapshot entry")
	assert_true(found_mirrored_first, "Snapshot opponent should mirror player grid positions")

func test_mirror_army_button() -> void:
	var game = await load_game()
	game._on_use_self_as_opponent_button_pressed()
	await process_frame

	assert_true(game.use_snapshot_opponent, "Mirror Army should enable snapshot opponent mode")
	assert_true(not game.opponent_army_snapshot.is_empty(), "Mirror Army should store an opponent snapshot")
	assert_eq(count_team_units(1), game.opponent_army_snapshot.size(), "Mirror Army should spawn snapshot opponent units")

	game.reset_game()
	assert_true(not game.use_snapshot_opponent, "New run should disable snapshot opponent mode")
	assert_true(game.opponent_army_snapshot.is_empty(), "New run should clear opponent army snapshot")

func test_interest_gold() -> void:
	var game = await load_game()
	game.player_gold = 0
	assert_eq(game.calculate_interest_gold(), 0, "0 gold should earn no interest")
	game.player_gold = 9
	assert_eq(game.calculate_interest_gold(), 0, "9 gold should earn no interest")
	game.player_gold = 10
	assert_eq(game.calculate_interest_gold(), 1, "10 gold should earn 1 interest")
	game.player_gold = 29
	assert_eq(game.calculate_interest_gold(), 2, "29 gold should earn 2 interest")
	game.player_gold = 99
	assert_eq(game.calculate_interest_gold(), game.interest_cap, "Interest should be capped")

	var gold_before := 29
	game.player_gold = gold_before
	game.last_round_result = "PLAYER WINS"
	game.restart_round()
	assert_eq(
		game.player_gold,
		gold_before + game.round_income + game.win_bonus_gold + 2,
		"Next round should add income, win bonus, and pre-income interest"
	)

func test_streak_bonuses() -> void:
	var game = await load_game()
	assert_eq(game.win_streak, 0, "Initial win streak should be 0")
	assert_eq(game.loss_streak, 0, "Initial loss streak should be 0")

	game.update_streaks_for_result("PLAYER WINS")
	game.update_streaks_for_result("PLAYER WINS")
	assert_eq(game.win_streak, 2, "Two wins should create a 2-win streak")
	assert_eq(game.loss_streak, 0, "Wins should reset loss streak")
	assert_eq(game.calculate_streak_bonus(), 1, "A 2-win streak should grant 1 bonus gold")

	game.update_streaks_for_result("PLAYER WINS")
	game.update_streaks_for_result("PLAYER WINS")
	assert_eq(game.calculate_streak_bonus(), game.max_streak_bonus, "A 4-win streak should grant max streak bonus")

	game.update_streaks_for_result("ENEMY WINS")
	assert_eq(game.win_streak, 0, "A loss should reset win streak")
	assert_eq(game.loss_streak, 1, "A loss should start a loss streak")

	game.update_streaks_for_result("DRAW")
	assert_eq(game.win_streak, 0, "A draw should reset win streak")
	assert_eq(game.loss_streak, 0, "A draw should reset loss streak")

	var gold_before := 40
	game.player_gold = gold_before
	game.win_streak = 2
	game.loss_streak = 0
	game.last_round_result = "PLAYER WINS"
	game.restart_round()
	assert_eq(
		game.player_gold,
		gold_before + game.round_income + game.win_bonus_gold + 4 + 1,
		"Next round should add income, win bonus, interest, and streak bonus"
	)

	game.reset_game()
	assert_eq(game.win_streak, 0, "New run should reset win streak")
	assert_eq(game.loss_streak, 0, "New run should reset loss streak")

func test_next_round_bonus() -> void:
	var game = await load_game()
	var round_before = game.round_number
	var gold_before = game.player_gold
	var interest_before = game.calculate_interest_gold()
	var streak_bonus_before = game.calculate_streak_bonus()
	game.last_round_result = "PLAYER WINS"
	game.restart_round()
	assert_eq(game.round_number, round_before + 1, "Round number should increase on restart")
	assert_eq(game.player_gold, gold_before + game.round_income + game.win_bonus_gold + interest_before + streak_bonus_before, "Gold should include income, win bonus, interest, and streak bonus")
	assert_eq(game.current_shop_offers.size(), game.shop_offer_count, "Shop offers should refresh after next round")
	assert_eq(game.sold_shop_offer_indices.size(), 0, "Sold shop slots should be cleared after next round")

func find_affordable_shop_offer(game) -> int:
	for i in range(game.current_shop_offers.size()):
		if not (i in game.sold_shop_offer_indices):
			var price = get_offer_price(game, i)
			if game.player_gold >= price:
				return i
	return -1

func get_offer_price(game, offer_index: int) -> int:
	return game.unit_database.get_unit_data(game.current_shop_offers[offer_index])["base_price"]

func find_empty_player_tile(game):
	for y in range(4, 8):
		for x in range(0, 8):
			var pos = Vector2i(x, y)
			if not game.is_tile_occupied(pos):
				return pos
	return null

func find_occupied_player_tile(game):
	for unit in get_nodes_in_group("units"):
		if unit.team_id == 0 and unit.current_hp > 0:
			return unit.grid_position
	return null

func has_player_unit_at_tile(tile: Vector2i) -> bool:
	for unit in get_nodes_in_group("units"):
		if unit.team_id == 0 and unit.grid_position == tile:
			return true
	return false

func count_team_units(team_id: int) -> int:
	var count = 0
	for unit in get_nodes_in_group("units"):
		if unit.team_id == team_id:
			count += 1
	return count

func event_log_contains_prefix(game, prefix: String) -> bool:
	for entry in game.event_log:
		if entry.begins_with(prefix):
			return true
	return false

func find_deployed_player_unit():
	for unit in get_nodes_in_group("units"):
		if unit.team_id == 0 and unit.current_hp > 0 and unit.has_meta("roster_id"):
			return unit
	return null

func find_player_unit_by_roster_id(roster_id: int):
	for unit in get_nodes_in_group("units"):
		if unit.is_queued_for_deletion():
			continue
		if unit.team_id == 0 and unit.has_meta("roster_id") and unit.get_meta("roster_id") == roster_id:
			return unit
	return null

func find_player_unit_by_unit_id(unit_id: String):
	for unit in get_nodes_in_group("units"):
		if unit.is_queued_for_deletion():
			continue
		if unit.team_id == 0 and unit.name == unit_id:
			return unit
	return null

func find_roster_entry(game, roster_id: int):
	for entry in game.player_roster:
		if entry.get("roster_id", -1) == roster_id:
			return entry
	return null

func buy_xp_for_extra_unit_cap(game) -> void:
	if game.player_roster.size() < game.max_player_units:
		return
	game._on_buy_xp_button_pressed()
	assert_true(game.player_roster.size() < game.max_player_units, "Buying XP should create room for one more deployed unit")

func assert_valid_shop_offers(game) -> void:
	for unit_id in game.current_shop_offers:
		assert_true(unit_id in game.shop_unit_ids, "Shop offer should come from shop_unit_ids")
		assert_true(not game.unit_database.get_unit_data(unit_id).is_empty(), "Shop offer should have unit data")

func assert_float_eq(actual: float, expected: float, message: String) -> void:
	if abs(actual - expected) > 0.001:
		print("FAIL ", current_test_name, ": ", message, " | actual=", str(actual), " expected=", str(expected))
		quit(1)
		return
