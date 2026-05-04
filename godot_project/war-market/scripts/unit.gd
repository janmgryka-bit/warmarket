extends CharacterBody3D

@export var unit_name: String = "Unit"
@export var team_id: int = 0

@export var max_hp: float = 100.0
@export var damage: float = 10.0
@export var attack_range: float = 1.4
@export var attack_cooldown: float = 1.0
@export var move_speed: float = 2.0

var current_hp: float
var target: CharacterBody3D = null
var attack_timer: float = 0.0
var battle_active: bool = false

func _ready() -> void:
	current_hp = max_hp
	add_to_group("units")
	print(unit_name, " ready. HP: ", current_hp)

func _physics_process(delta: float) -> void:
	if not battle_active:
		return
	
	if current_hp <= 0:
		return
	
	attack_timer -= delta
	
	if target == null or not is_instance_valid(target) or target.current_hp <= 0:
		target = find_nearest_enemy()
	
	if target == null:
		velocity = Vector3.ZERO
		move_and_slide()
		return
	
	var distance := global_position.distance_to(target.global_position)
	
	if distance > attack_range:
		var direction := (target.global_position - global_position).normalized()
		velocity = direction * move_speed
		move_and_slide()
	else:
		velocity = Vector3.ZERO
		move_and_slide()
		
		if attack_timer <= 0.0:
			attack(target)
			attack_timer = attack_cooldown

func find_nearest_enemy() -> CharacterBody3D:
	var units := get_tree().get_nodes_in_group("units")
	var nearest: CharacterBody3D = null
	var nearest_distance := INF
	
	for unit in units:
		if unit == self:
			continue
		
		if unit.team_id == team_id:
			continue
		
		if unit.current_hp <= 0:
			continue
		
		var dist := global_position.distance_to(unit.global_position)
		
		if dist < nearest_distance:
			nearest_distance = dist
			nearest = unit
	
	return nearest

func attack(enemy: CharacterBody3D) -> void:
	print(unit_name, " attacks ", enemy.unit_name)
	enemy.take_damage(damage)

func take_damage(amount: float) -> void:
	current_hp -= amount
	print(unit_name, " HP: ", current_hp)
	
	if current_hp <= 0:
		die()

func die() -> void:
	print(unit_name, " died")
	queue_free()

func start_battle() -> void:
	battle_active = true
	print(unit_name, " starts battle")

func stop_battle() -> void:
	battle_active = false
	velocity = Vector3.ZERO
