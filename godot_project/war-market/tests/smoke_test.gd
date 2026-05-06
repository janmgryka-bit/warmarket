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
	await run_test("Reroll", Callable(self, "test_reroll"))
	await run_test("Buy to bench", Callable(self, "test_buy_to_bench"))
	await run_test("Sold slot", Callable(self, "test_sold_slot"))
	await run_test("Bench sell", Callable(self, "test_bench_sell"))
	await run_test("Bench deploy", Callable(self, "test_bench_deploy"))
	await run_test("Invalid bench deploy", Callable(self, "test_invalid_bench_deploy"))
	await run_test("Unit cap", Callable(self, "test_unit_cap"))
	await run_test("Deployed sell", Callable(self, "test_deployed_sell"))
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
	assert_eq(game.round_number, 1, "Round should start at 1")
	assert_eq(game.current_shop_offers.size(), game.shop_offer_count, "Shop should show the configured number of offers")
	assert_eq(game.bench_units.size(), 0, "Bench should be empty at start")

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

func test_bench_deploy() -> void:
	var game = await load_game()
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
