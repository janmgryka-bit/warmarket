extends SceneTree

func assert_true(condition: bool, message: String) -> void:
	if not condition:
		print("ASSERTION FAILED: ", message)
		quit(1)

func _init() -> void:
	print("Starting smoke test...")
	
	# Load and instantiate the main scene
	var main_scene = load("res://scenes/Main.tscn")
	var main = main_scene.instantiate()
	root.add_child(main)
	
	# Wait a couple frames for _ready to run
	await process_frame
	await process_frame
	
	# Use the instantiated Main scene directly
	var game = main
	assert_true(game != null, "Main node not found")
	
	# Basic state checks
	assert_true(game.player_gold == game.starting_gold, "Initial gold should be starting_gold")
	assert_true(game.current_shop_offers.size() == game.shop_offer_count, "Shop offers count mismatch")
	assert_true(game.bench_units.size() == 0, "Bench should start empty")
	assert_true(game.player_roster.size() >= 0 and game.player_roster.size() <= game.max_player_units, "Player roster size invalid")
	
	# Test reroll
	var gold_before_reroll = game.player_gold
	game._on_reroll_button_pressed()
	if gold_before_reroll >= game.reroll_cost:
		assert_true(game.player_gold == gold_before_reroll - game.reroll_cost, "Reroll should cost reroll_cost")
	else:
		assert_true(game.player_gold == gold_before_reroll, "Reroll should not change gold if insufficient")
	
	# Test buy to bench
	var shop_offers_before = game.current_shop_offers.duplicate()
	var bench_size_before = game.bench_units.size()
	var gold_before_buy = game.player_gold
	
	# Find first non-sold offer
	var bought = false
	for i in range(game.current_shop_offers.size()):
		if not (i in game.sold_shop_offer_indices):
			var unit_id = game.current_shop_offers[i]
			var data = game.unit_database.get_unit_data(unit_id)
			if data and game.player_gold >= data["base_price"] and game.bench_units.size() < game.max_bench_units:
				game._on_shop_card_pressed(unit_id, i)
				assert_true(game.bench_units.size() == bench_size_before + 1, "Bench size should increase after buy")
				assert_true(game.player_gold == gold_before_buy - data["base_price"], "Gold should decrease by unit price")
				assert_true(i in game.sold_shop_offer_indices, "Shop slot should be marked sold")
				bought = true
				break
	
	if not bought:
		print("Could not test buy (no affordable units or bench full)")
	
	# Test bench deploy
	if game.bench_units.size() > 0:
		var bench_size_before_deploy = game.bench_units.size()
		var roster_size_before_deploy = game.player_roster.size()
		game.selected_bench_index = 0
		var deployed = game.try_deploy_bench_unit(Vector2i(3, 6))  # Assuming valid empty tile
		if deployed:
			assert_true(game.bench_units.size() == bench_size_before_deploy - 1, "Bench size should decrease after deploy")
			assert_true(game.player_roster.size() == roster_size_before_deploy + 1, "Roster size should increase after deploy")
		else:
			print("Could not deploy bench unit (tile occupied or other issue)")
	
	# Test sell deployed unit
	if game.player_roster.size() > 0:
		var roster_size_before_sell = game.player_roster.size()
		var gold_before_sell = game.player_gold
		
		# Find a deployed unit
		var units = get_nodes_in_group("units")
		var player_unit = null
		for unit in units:
			if unit.team_id == 0 and unit.current_hp > 0:
				player_unit = unit
				break
		
		if player_unit:
			game.selected_unit = player_unit
			game._on_sell_unit_button_pressed()
			assert_true(game.player_roster.size() == roster_size_before_sell - 1, "Roster size should decrease after sell")
			# Gold check would require knowing the unit price, skip for simplicity
		else:
			print("No player unit found to sell")
	
	# Test next round
	var round_before = game.round_number
	var gold_before_next = game.player_gold
	game.last_round_result = "PLAYER WINS"
	game.restart_round()
	assert_true(game.round_number == round_before + 1, "Round number should increase")
	assert_true(game.player_gold == gold_before_next + game.round_income + game.win_bonus_gold, "Gold should increase by income + win bonus")
	assert_true(game.current_shop_offers.size() == game.shop_offer_count, "Shop should refresh")
	assert_true(game.sold_shop_offer_indices.size() == 0, "Sold indices should be cleared")
	
	print("SMOKE TEST PASSED")
	quit(0)