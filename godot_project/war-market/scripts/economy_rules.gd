extends Node

static func calculate_interest_gold(player_gold: int, interest_cap: int) -> int:
	return min(int(floor(float(player_gold) / 10.0)), interest_cap)

static func calculate_streak_bonus(streak_count: int, max_streak_bonus: int) -> int:
	if streak_count < 2:
		return 0
	if streak_count < 4:
		return 1
	return max_streak_bonus

static func get_xp_required_for_level(player_level: int) -> int:
	return player_level * 2

static func get_max_player_units_for_level(player_level: int) -> int:
	return player_level + 1

static func get_round_loss_damage(round_number: int) -> int:
	if round_number <= 2:
		return 2
	if round_number <= 4:
		return 3
	if round_number <= 6:
		return 4
	if round_number <= 8:
		return 5
	return 6
