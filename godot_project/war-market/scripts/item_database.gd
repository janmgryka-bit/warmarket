extends Node

const ITEMS := {
	"training_sword": {
		"name": "Training Sword",
		"damage_bonus": 10.0
	},
	"wooden_shield": {
		"name": "Wooden Shield",
		"max_hp_bonus": 50.0
	},
	"longbow": {
		"name": "Longbow",
		"attack_range_bonus": 1.0
	},
	"war_drum": {
		"name": "War Drum",
		"attack_cooldown_multiplier": 0.9
	}
}

static func get_item_data(item_id: String) -> Dictionary:
	if not ITEMS.has(item_id):
		push_error("Unknown item id: " + item_id)
		return {}

	return ITEMS[item_id]

static func get_item_name(item_id: String) -> String:
	return get_item_data(item_id).get("name", item_id)

static func get_all_item_ids() -> Array[String]:
	var item_ids: Array[String] = []
	for item_id in ITEMS.keys():
		item_ids.append(item_id)
	return item_ids
