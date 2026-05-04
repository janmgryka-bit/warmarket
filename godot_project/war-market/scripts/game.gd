extends Node3D

@onready var board: Node3D = $Board
@onready var units_container: Node3D = $Units
@onready var start_button: Button = $UI/StartBattleButton

var unit_scene: PackedScene = preload("res://units/Unit.tscn")
var battle_started: bool = false

func _ready() -> void:
	print("GAME READY")
	
	if start_button == null:
		print("ERROR: StartBattleButton not found")
	else:
		print("StartBattleButton found")
	
	spawn_test_units()

func spawn_test_units() -> void:
	var roman = unit_scene.instantiate()
	roman.name = "RomanLegionary"
	roman.unit_name = "Legionista"
	roman.team_id = 0
	roman.max_hp = 140
	roman.damage = 12
	roman.attack_cooldown = 1.0
	roman.move_speed = 2.0
	units_container.add_child(roman)
	roman.global_position = board.get_spawn_position(Vector2i(2, 1))
	
	var viking = unit_scene.instantiate()
	viking.name = "VikingBerserker"
	viking.unit_name = "Berserker"
	viking.team_id = 1
	viking.max_hp = 110
	viking.damage = 18
	viking.attack_cooldown = 1.1
	viking.move_speed = 2.3
	units_container.add_child(viking)
	viking.global_position = board.get_spawn_position(Vector2i(5, 6))

func _on_start_battle_button_pressed() -> void:
	print("BUTTON CLICKED")
	start_battle()

func start_battle() -> void:
	if battle_started:
		return
	
	battle_started = true
	print("BATTLE STARTED")
	
	var units := get_tree().get_nodes_in_group("units")
	for unit in units:
		unit.start_battle()
