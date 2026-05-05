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
	}
}

static func get_unit_data(unit_id: String) -> Dictionary:
	if not UNITS.has(unit_id):
		push_error("Unknown unit id: " + unit_id)
		return {}
	
	return UNITS[unit_id]
