extends Node

static func create_army_snapshot_from_roster(roster: Array[Dictionary]) -> Array[Dictionary]:
	var snapshot: Array[Dictionary] = []
	for entry in roster:
		var snapshot_entry := {
			"unit_id": entry.get("unit_id", ""),
			"grid_pos": entry.get("grid_pos", Vector2i.ZERO),
			"star_level": entry.get("star_level", 1)
		}
		var item_ids = entry.get("item_ids", [])
		if not item_ids.is_empty():
			snapshot_entry["item_ids"] = item_ids.duplicate()
		snapshot.append(snapshot_entry)
	return snapshot

static func mirror_grid_pos_for_opponent(grid_pos: Vector2i, board_size: int = 8) -> Vector2i:
	return Vector2i(grid_pos.x, board_size - 1 - grid_pos.y)

static func create_unit_snapshot_from_unit(unit) -> Dictionary:
	var snapshot := {
		"unit_id": String(unit.name),
		"grid_pos": unit.grid_position,
		"star_level": get_unit_star_level(unit)
	}
	if unit.has_meta("item_ids"):
		var item_ids = unit.get_meta("item_ids")
		if not item_ids.is_empty():
			snapshot["item_ids"] = item_ids.duplicate()
	return snapshot

static func create_surviving_units_snapshot(units: Array) -> Array[Dictionary]:
	var snapshot: Array[Dictionary] = []
	for unit in units:
		if not is_instance_valid(unit) or unit.current_hp <= 0:
			continue
		snapshot.append({
			"unit_id": String(unit.name),
			"team_id": unit.team_id,
			"star_level": get_unit_star_level(unit),
			"current_hp": unit.current_hp,
			"max_hp": unit.max_hp,
			"grid_pos": unit.grid_position
		})
	return snapshot

static func create_battle_payload(data: Dictionary) -> Dictionary:
	return {
		"battle_id": data.get("battle_id", 0),
		"battle_seed": data.get("battle_seed", 0),
		"round_number": data.get("round_number", 0),
		"player_level": data.get("player_level", 1),
		"player_health": data.get("player_health", 0),
		"player_gold": data.get("player_gold", 0),
		"player_army_snapshot": data.get("player_army_snapshot", []),
		"opponent_source": data.get("opponent_source", "pve_wave"),
		"opponent_army_snapshot": data.get("opponent_army_snapshot", [])
	}

static func create_battle_summary(data: Dictionary) -> Dictionary:
	return {
		"battle_id": data.get("battle_id", 0),
		"battle_seed": data.get("battle_seed", 0),
		"round_number": data.get("round_number", 0),
		"result": data.get("result", ""),
		"player_health": data.get("player_health", 0),
		"player_level": data.get("player_level", 1),
		"player_gold": data.get("player_gold", 0),
		"player_army_snapshot": data.get("player_army_snapshot", []),
		"opponent_source": data.get("opponent_source", "pve_wave"),
		"opponent_army_snapshot": data.get("opponent_army_snapshot", []),
		"surviving_units": data.get("surviving_units", []),
		"player_damage_taken": data.get("player_damage_taken", 0)
	}

static func get_unit_star_level(unit) -> int:
	if unit.has_meta("star_level"):
		return unit.get_meta("star_level")
	var star_level = unit.get("star_level")
	if star_level == null:
		return 1
	return star_level
