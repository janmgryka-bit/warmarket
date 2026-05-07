extends Node

static func count_factions(roster: Array[Dictionary], unit_database) -> Dictionary:
	var counts: Dictionary = {}
	for entry in roster:
		var unit_id = entry.get("unit_id", "")
		var data: Dictionary = unit_database.get_unit_data(unit_id)
		if data.is_empty():
			continue
		var faction = data.get("faction", "")
		if faction == "":
			continue
		counts[faction] = counts.get(faction, 0) + 1
	return counts

static func count_roles(roster: Array[Dictionary], unit_database) -> Dictionary:
	var counts: Dictionary = {}
	for entry in roster:
		var unit_id = entry.get("unit_id", "")
		var data: Dictionary = unit_database.get_unit_data(unit_id)
		if data.is_empty():
			continue
		var role = data.get("role", "")
		if role == "":
			continue
		counts[role] = counts.get(role, 0) + 1
	return counts

static func get_active_faction_bonuses(faction_counts: Dictionary) -> Dictionary:
	var bonuses: Dictionary = {}
	if faction_counts.get("Romans", 0) >= 2:
		bonuses["Romans"] = {"max_hp_multiplier": 1.2}
	if faction_counts.get("Vikings", 0) >= 2:
		bonuses["Vikings"] = {"damage_multiplier": 1.2}
	if faction_counts.get("Mongols", 0) >= 2:
		bonuses["Mongols"] = {"attack_range_multiplier": 1.15}
	if faction_counts.get("Slavs", 0) >= 2:
		bonuses["Slavs"] = {"attack_cooldown_multiplier": 0.85}
	return bonuses

static func get_active_role_bonuses(role_counts: Dictionary) -> Dictionary:
	var bonuses: Dictionary = {}
	if role_counts.get("Tank", 0) >= 2:
		bonuses["Tank"] = {"max_hp_multiplier": 1.2}
	if role_counts.get("Fighter", 0) >= 2:
		bonuses["Fighter"] = {"damage_multiplier": 1.15}
	if role_counts.get("Ranged", 0) >= 2:
		bonuses["Ranged"] = {"attack_range_multiplier": 1.1}
	return bonuses

static func get_synergy_summary_text(faction_counts: Dictionary, role_counts: Dictionary) -> String:
	var active_faction_bonuses = get_active_faction_bonuses(faction_counts)
	var active_role_bonuses = get_active_role_bonuses(role_counts)
	if active_faction_bonuses.is_empty() and active_role_bonuses.is_empty():
		return "Synergies: None"

	var lines: Array[String] = ["Synergies:"]
	if active_faction_bonuses.has("Romans"):
		lines.append("Romans %d/2: +HP" % faction_counts.get("Romans", 0))
	if active_faction_bonuses.has("Vikings"):
		lines.append("Vikings %d/2: +DMG" % faction_counts.get("Vikings", 0))
	if active_faction_bonuses.has("Mongols"):
		lines.append("Mongols %d/2: +RNG" % faction_counts.get("Mongols", 0))
	if active_faction_bonuses.has("Slavs"):
		lines.append("Slavs %d/2: +AS" % faction_counts.get("Slavs", 0))
	if active_role_bonuses.has("Tank"):
		lines.append("Tank %d/2: +HP" % role_counts.get("Tank", 0))
	if active_role_bonuses.has("Fighter"):
		lines.append("Fighter %d/2: +DMG" % role_counts.get("Fighter", 0))
	if active_role_bonuses.has("Ranged"):
		lines.append("Ranged %d/2: +RNG" % role_counts.get("Ranged", 0))
	return "\n".join(lines)
