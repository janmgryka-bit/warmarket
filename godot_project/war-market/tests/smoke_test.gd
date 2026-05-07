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
	await run_test("Buy XP", Callable(self, "test_buy_xp"))
	await run_test("Shop tier rolls", Callable(self, "test_shop_tier_rolls"))
	await run_test("Faction bonuses", Callable(self, "test_faction_bonuses"))
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
	await run_test("Invalid bench deploy", Callable(self, "test_invalid_bench_deploy"))
	await run_test("Unit cap", Callable(self, "test_unit_cap"))
	await run_test("Deployed sell", Callable(self, "test_deployed_sell"))
	await run_test("Game over after loss", Callable(self, "test_game_over_after_loss"))
	await run_test("Reset game new run", Callable(self, "test_reset_game_new_run"))
	await run_test("Enemy wave spawning", Callable(self, "test_enemy_wave_spawning"))
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
	assert_eq(game.player_level_label.text, "Level: 1 (0/2 XP)", "Player level label should show initial XP progress")

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
	assert_float_eq(viking_unit.damage, viking_base_damage * 1.2, "Viking synergy should increase Viking damage")

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
	game.selected_bench_index = game.bench_units.size() - 1
	var deployed = game.try_deploy_bench_unit(tile)
	assert_true(deployed, "Bench deploy should succeed on a valid empty tile")
	assert_eq(game.bench_units.size(), bench_before - 1, "Bench size should decrease after deploy")
	assert_eq(game.player_roster.size(), roster_before + 1, "Roster size should increase after deploy")
	assert_true(has_player_unit_at_tile(tile), "A player unit should be spawned at the deployed tile")

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
	game.player_health = game.loss_damage
	game.end_round("ENEMY WINS")
	assert_eq(game.player_health, 0, "Player health should be clamped to zero after loss")
	assert_true(game.game_over, "Game over should be true after health reaches zero")
	assert_eq(game.round_result_label.text, "GAME OVER", "Round result label should show GAME OVER")

func test_reset_game_new_run() -> void:
	var game = await load_game()
	# Force game over
	game.player_health = game.loss_damage
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

func test_next_round_bonus() -> void:
	var game = await load_game()
	var round_before = game.round_number
	var gold_before = game.player_gold
	game.last_round_result = "PLAYER WINS"
	game.restart_round()
	assert_eq(game.round_number, round_before + 1, "Round number should increase on restart")
	assert_eq(game.player_gold, gold_before + game.round_income + game.win_bonus_gold, "Gold should include income and win bonus")
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
