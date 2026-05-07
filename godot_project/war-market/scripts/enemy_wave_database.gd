extends Node

# PvE wave generator definitions by round.
# These temporary PvE waves currently provide the fallback opponent army.
const WAVES := {
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

static func get_wave_definition(round_number: int) -> Array[Dictionary]:
	var wave_round = round_number
	if not has_wave(wave_round):
		wave_round = get_highest_wave_round()

	var wave_definition: Array[Dictionary] = []
	for entry in WAVES.get(wave_round, []):
		wave_definition.append(entry.duplicate())
	return wave_definition

static func has_wave(round_number: int) -> bool:
	return WAVES.has(round_number)

static func get_highest_wave_round() -> int:
	var highest_round := 0
	for wave_round in WAVES.keys():
		highest_round = max(highest_round, int(wave_round))
	return highest_round
