extends CharacterBody3D

@export var unit_name: String = "Unit"
@export var team_id: int = 0

var grid_position: Vector2i = Vector2i(-1, -1)

@export var max_hp: float = 100.0
@export var damage: float = 10.0
@export var attack_range: float = 1.4
@export var attack_cooldown: float = 1.0
@export var move_speed: float = 2.0

var current_hp: float
var target: CharacterBody3D = null
var attack_timer: float = 0.0
var battle_active: bool = false

@onready var body_mesh: MeshInstance3D = $MeshInstance3D
@onready var health_bar: Node3D = $HealthBar
@onready var hp_back: MeshInstance3D = $HealthBar/HpBack
@onready var hp_fill: MeshInstance3D = $HealthBar/HpFill

func _ready() -> void:
	current_hp = max_hp
	add_to_group("units")
	apply_team_color()
	setup_health_bar()
	update_health_bar()
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
	current_hp = max(current_hp, 0.0)
	update_health_bar()
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

func apply_team_color() -> void:
	var material := StandardMaterial3D.new()
	
	if team_id == 0:
		material.albedo_color = Color(0.2, 0.45, 1.0)
	else:
		material.albedo_color = Color(1.0, 0.25, 0.2)
	
	body_mesh.material_override = material

func setup_health_bar() -> void:
	var back_material := StandardMaterial3D.new()
	back_material.albedo_color = Color(0.05, 0.05, 0.05)
	back_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hp_back.material_override = back_material
	
	var fill_material := StandardMaterial3D.new()
	fill_material.albedo_color = Color(0.1, 1.0, 0.2)
	fill_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hp_fill.material_override = fill_material

func update_health_bar() -> void:
	if hp_fill == null:
		return
	
	var hp_ratio := current_hp / max_hp
	hp_ratio = clamp(hp_ratio, 0.0, 1.0)
	
	hp_fill.scale.x = hp_ratio
	
	# Przesuwamy pasek w lewo, żeby znikał od prawej strony.
	hp_fill.position.x = -0.5 * (1.0 - hp_ratio)
