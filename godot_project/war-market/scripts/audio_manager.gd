extends Node

@export var ui_click_sound: AudioStream
@export var buy_sound: AudioStream
@export var sell_sound: AudioStream
@export var reroll_sound: AudioStream
@export var merge_sound: AudioStream
@export var start_battle_sound: AudioStream
@export var hit_sound: AudioStream
@export var death_sound: AudioStream
@export var victory_sound: AudioStream
@export var game_over_sound: AudioStream

var muted: bool = false

func set_muted(value: bool) -> void:
	muted = value

func toggle_muted() -> bool:
	muted = not muted
	return muted

func is_muted() -> bool:
	return muted

func play_stream(stream: AudioStream) -> void:
	if muted:
		return
	if stream == null:
		return

	var player := AudioStreamPlayer.new()
	player.stream = stream
	add_child(player)
	player.finished.connect(func(): player.queue_free())
	player.play()

func play_ui_click() -> void:
	play_stream(ui_click_sound)

func play_buy() -> void:
	play_stream(buy_sound)

func play_sell() -> void:
	play_stream(sell_sound)

func play_reroll() -> void:
	play_stream(reroll_sound)

func play_merge() -> void:
	play_stream(merge_sound)

func play_start_battle() -> void:
	play_stream(start_battle_sound)

func play_hit() -> void:
	play_stream(hit_sound)

func play_death() -> void:
	play_stream(death_sound)

func play_victory() -> void:
	play_stream(victory_sound)

func play_game_over() -> void:
	play_stream(game_over_sound)
