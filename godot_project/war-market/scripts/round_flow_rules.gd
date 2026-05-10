extends Node

const ROUND_TYPE_NEUTRAL := "neutral"
const ROUND_TYPE_PVP := "pvp"

static func get_round_type(round_number: int) -> String:
	if is_neutral_round(round_number):
		return ROUND_TYPE_NEUTRAL
	return ROUND_TYPE_PVP

static func is_neutral_round(round_number: int) -> bool:
	if round_number == 1:
		return true
	if round_number == 4 or round_number == 8:
		return true
	if round_number > 8 and round_number % 4 == 0:
		return true
	return false
