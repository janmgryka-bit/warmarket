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
		"attack_range": 1.4
	},
	
	"roman_archer": {
		"name": "Rzymski Łucznik",
		"faction": "Romans",
		"role": "Ranged",
		"tier": 1,
		"base_price": 4,
		"max_hp": 80,
		"damage": 9,
		"attack_cooldown": 1.2,
		"move_speed": 2.0,
		"attack_range": 4.0
	},
	
	"viking_berserker": {
		"name": "Berserker",
		"faction": "Vikings",
		"role": "Fighter",
		"tier": 1,
		"base_price": 5,
		"max_hp": 110,
		"damage": 18,
		"attack_cooldown": 1.1,
		"move_speed": 2.3,
		"attack_range": 1.4
	},
	
	"roman_spearman": {
		"name": "Roman Spearman",
		"faction": "Romans",
		"role": "Fighter",
		"tier": 1,
		"base_price": 3,
		"max_hp": 100,
		"damage": 14,
		"attack_cooldown": 1.1,
		"move_speed": 2.0,
		"attack_range": 1.6
	},
	
	"viking_axeman": {
		"name": "Viking Axeman",
		"faction": "Vikings",
		"role": "Fighter",
		"tier": 1,
		"base_price": 3,
		"max_hp": 95,
		"damage": 16,
		"attack_cooldown": 1.2,
		"move_speed": 2.3,
		"attack_range": 1.3
	},
	
	"slav_hunter": {
		"name": "Slav Hunter",
		"faction": "Slavs",
		"role": "Ranged",
		"tier": 1,
		"base_price": 3,
		"max_hp": 75,
		"damage": 10,
		"attack_cooldown": 1.0,
		"move_speed": 2.0,
		"attack_range": 4.0
	},
	
	"roman_centurion": {
		"name": "Roman Centurion",
		"faction": "Romans",
		"role": "Tank",
		"tier": 2,
		"base_price": 6,
		"max_hp": 220,
		"damage": 22,
		"attack_cooldown": 1.1,
		"move_speed": 2.0,
		"attack_range": 1.5
	},
	
	"viking_raider": {
		"name": "Viking Raider",
		"faction": "Vikings",
		"role": "Fighter",
		"tier": 2,
		"base_price": 6,
		"max_hp": 170,
		"damage": 30,
		"attack_cooldown": 1.0,
		"move_speed": 2.3,
		"attack_range": 1.3
	},
	
	"mongol_horse_archer": {
		"name": "Mongol Horse Archer",
		"faction": "Mongols",
		"role": "Ranged",
		"tier": 2,
		"base_price": 6,
		"max_hp": 120,
		"damage": 22,
		"attack_cooldown": 0.95,
		"move_speed": 2.5,
		"attack_range": 4.5
	}
}

static func get_unit_data(unit_id: String) -> Dictionary:
	if not UNITS.has(unit_id):
		push_error("Unknown unit id: " + unit_id)
		return {}
	
	return UNITS[unit_id]
