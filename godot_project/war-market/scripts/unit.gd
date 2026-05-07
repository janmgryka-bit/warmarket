extends CharacterBody3D

signal unit_clicked(unit)

@export var unit_name: String = "Unit"
@export var team_id: int = 0
@export var role: String = "Fighter"

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
var is_selected: bool = false
var star_level: int = 1

@onready var body_mesh: MeshInstance3D = $MeshInstance3D
@onready var health_bar: Node3D = $HealthBar
@onready var hp_back: MeshInstance3D = $HealthBar/HpBack
@onready var hp_fill: MeshInstance3D = $HealthBar/HpFill
@onready var star_label: Label3D = $StarLabel

func _ready() -> void:
	current_hp = max_hp
	input_ray_pickable = true
	input_event.connect(_on_input_event)
	add_to_group("units")
	apply_team_color()
	apply_role_shape()
	setup_health_bar()
	update_health_bar()
	set_star_level(star_level)
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
		face_position(target.global_position)
		var direction := (target.global_position - global_position).normalized()
		velocity = direction * move_speed
		move_and_slide()
	else:
		face_position(target.global_position)
		velocity = Vector3.ZERO
		move_and_slide()
		
		if attack_timer <= 0.0:
			attack(target)
			attack_timer = attack_cooldown

func _on_input_event(
	_camera: Camera3D,
	event: InputEvent,
	_position: Vector3,
	_normal: Vector3,
	_shape_idx: int
) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			print("UNIT CLICKED: ", unit_name)
			unit_clicked.emit(self)

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
	face_position(enemy.global_position)
	play_attack_visual(enemy)
	enemy.take_damage(damage)

func face_position(target_position: Vector3) -> void:
	var flat_target := Vector3(target_position.x, global_position.y, target_position.z)
	var direction := flat_target - global_position
	if direction.length_squared() <= 0.0001:
		return
	
	var target_yaw := atan2(direction.x, direction.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, 0.25)

func play_attack_visual(target_node: Node3D) -> void:
	if target_node == null or not is_instance_valid(target_node):
		return
	
	if attack_range > 2.0:
		play_ranged_attack_visual(target_node)
	else:
		play_melee_attack_visual(target_node)

func play_ranged_attack_visual(target_node: Node3D) -> void:
	var projectile := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.08
	mesh.height = 0.16
	projectile.mesh = mesh
	projectile.material_override = create_attack_visual_material(Color(1.0, 0.85, 0.25, 1.0))
	get_tree().current_scene.add_child(projectile)
	
	projectile.global_position = global_position + Vector3(0.0, 1.1, 0.0)
	var target_position := target_node.global_position + Vector3(0.0, 1.0, 0.0)
	
	var tween := create_tween()
	tween.tween_property(projectile, "global_position", target_position, 0.2)
	tween.tween_callback(projectile.queue_free)

func play_melee_attack_visual(target_node: Node3D) -> void:
	var impact := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.14
	mesh.height = 0.28
	impact.mesh = mesh
	impact.material_override = create_attack_visual_material(Color(1.0, 0.95, 0.55, 1.0))
	get_tree().current_scene.add_child(impact)
	
	impact.global_position = target_node.global_position + Vector3(0.0, 1.0, 0.0)
	impact.scale = Vector3(0.4, 0.4, 0.4)
	
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(impact, "scale", Vector3(1.2, 1.2, 1.2), 0.18)
	tween.tween_property(impact, "material_override:albedo_color:a", 0.0, 0.18)
	tween.set_parallel(false)
	tween.tween_callback(impact.queue_free)

func create_attack_visual_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material

func take_damage(amount: float) -> void:
	current_hp -= amount
	current_hp = max(current_hp, 0.0)
	update_health_bar()
	show_damage_number(amount)
	print(unit_name, " HP: ", current_hp)
	
	if current_hp <= 0:
		die()

func show_damage_number(amount: float) -> void:
	var label := Label3D.new()
	label.text = "-%d" % int(round(amount))
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.modulate = Color(1.0, 0.2, 0.1, 1.0)
	label.font_size = 42
	label.position = Vector3(0.0, 2.25, 0.0)
	add_child(label)
	
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position", label.position + Vector3(0.0, 0.8, 0.0), 0.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.8)
	tween.set_parallel(false)
	tween.tween_callback(label.queue_free)

func die() -> void:
	print(unit_name, " died")
	queue_free()

func start_battle() -> void:
	battle_active = true
	set_selected(false)
	print(unit_name, " starts battle")

func stop_battle() -> void:
	battle_active = false
	velocity = Vector3.ZERO

func set_selected(value: bool) -> void:
	is_selected = value
	update_selection_visual()

func apply_team_color() -> void:
	var material := StandardMaterial3D.new()
	
	if team_id == 0:
		material.albedo_color = Color(0.2, 0.45, 1.0)
	else:
		material.albedo_color = Color(1.0, 0.25, 0.2)
	
	body_mesh.material_override = material

func update_selection_visual() -> void:
	var material := StandardMaterial3D.new()
	
	if is_selected:
		material.albedo_color = Color(0.2, 1.0, 0.4)
	elif team_id == 0:
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
	hp_fill.position.x = -0.5 * (1.0 - hp_ratio)

func apply_role_shape() -> void:
	match role:
		"Tank":
			body_mesh.scale = Vector3(1.15, 1.1, 1.15)
		"Ranged":
			body_mesh.scale = Vector3(0.75, 0.85, 0.75)
		"Fighter":
			body_mesh.scale = Vector3(1.0, 1.0, 1.0)
		_:
			body_mesh.scale = Vector3(1.0, 1.0, 1.0)

func set_star_level(value: int) -> void:
	star_level = value
	if star_label != null:
		match star_level:
			1:
				star_label.text = "★"
			2:
				star_label.text = "★★"
			_:
				star_label.text = "★".repeat(star_level)
