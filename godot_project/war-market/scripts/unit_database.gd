extends Node

const UNITS := {
	"roman_legionary": {
		"name": "Legionista",
		"faction": "Romans",
		"role": "Tank",
		"tier": 1,
		"base_price": 3,
		"max_hp": 140,
		"damage": 12,
		"attack_cooldown": 1.0,
		"move_speed": 2.0,
		"attack_range": 1.4,
		"damage_taken_multiplier": 0.95
	},
	
	"roman_archer": {
		"name": "Rzymski Łucznik",
		"faction": "Romans",
		"role": "Ranged",
		"tier": 1,
		"base_price": 4,
		"max_hp": 70,
		"damage": 11,
		"attack_cooldown": 1.35,
		"move_speed": 1.9,
		"attack_range": 5.2
	},
	
	"viking_berserker": {
		"name": "Berserker",
		"faction": "Vikings",
		"role": "Fighter",
		"tier": 1,
		"base_price": 5,
		"max_hp": 105,
		"damage": 19,
		"attack_cooldown": 1.0,
		"move_speed": 2.3,
		"attack_range": 1.4
	},
	
	"roman_spearman": {
		"name": "Roman Spearman",
		"faction": "Romans",
		"role": "Fighter",
		"tier": 1,
		"base_price": 3,
		"max_hp": 150,
		"damage": 11,
		"attack_cooldown": 1.25,
		"move_speed": 1.9,
		"attack_range": 1.8,
		"damage_taken_multiplier": 0.9
	},
	
	"viking_axeman": {
		"name": "Viking Axeman",
		"faction": "Vikings",
		"role": "Fighter",
		"tier": 1,
		"base_price": 3,
		"max_hp": 90,
		"damage": 20,
		"attack_cooldown": 0.95,
		"move_speed": 2.35,
		"attack_range": 1.3
	},
	
	"slav_hunter": {
		"name": "Slav Hunter",
		"faction": "Slavs",
		"role": "Ranged",
		"tier": 1,
		"base_price": 3,
		"max_hp": 70,
		"damage": 11,
		"attack_cooldown": 1.15,
		"move_speed": 2.0,
		"attack_range": 4.8
	},
	
	"roman_centurion": {
		"name": "Roman Centurion",
		"faction": "Romans",
		"role": "Tank",
		"tier": 2,
		"base_price": 6,
		"max_hp": 230,
		"damage": 24,
		"attack_cooldown": 1.15,
		"move_speed": 2.0,
		"attack_range": 1.5,
		"damage_taken_multiplier": 0.88
	},
	
	"viking_raider": {
		"name": "Viking Raider",
		"faction": "Vikings",
		"role": "Fighter",
		"tier": 2,
		"base_price": 6,
		"max_hp": 165,
		"damage": 34,
		"attack_cooldown": 0.9,
		"move_speed": 2.4,
		"attack_range": 1.3
	},
	
	"mongol_horse_archer": {
		"name": "Mongol Horse Archer",
		"faction": "Mongols",
		"role": "Ranged",
		"tier": 2,
		"base_price": 6,
		"max_hp": 115,
		"damage": 24,
		"attack_cooldown": 1.05,
		"move_speed": 2.5,
		"attack_range": 5.4
	}
}

static func get_unit_data(unit_id: String) -> Dictionary:
	if not UNITS.has(unit_id):
		push_error("Unknown unit id: " + unit_id)
		return {}
	
	return UNITS[unit_id]
