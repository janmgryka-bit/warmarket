extends CharacterBody3D

signal unit_clicked(unit)

@export var unit_name: String = "Unit"
@export var team_id: int = 0
@export var faction: String = "Romans"
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
var is_dead: bool = false

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
	apply_visual_attachments()
	setup_health_bar()
	update_health_bar()
	set_star_level(star_level)
	print(unit_name, " ready. HP: ", current_hp)

func _physics_process(delta: float) -> void:
	if not battle_active:
		return
	
	if is_dead or current_hp <= 0:
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
	if is_dead:
		return
	
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
	if is_dead:
		return
	
	is_dead = true
	battle_active = false
	velocity = Vector3.ZERO
	target = null
	input_ray_pickable = false
	print(unit_name, " died")
	play_death_visual()

func play_death_visual() -> void:
	var flash := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.35
	mesh.height = 0.7
	flash.mesh = mesh
	flash.material_override = create_attack_visual_material(Color(1.0, 0.35, 0.15, 0.85))
	
	var effect_parent: Node = get_tree().current_scene
	if effect_parent == null:
		effect_parent = get_parent()
	if effect_parent != null:
		effect_parent.add_child(flash)
		flash.global_position = global_position + Vector3(0.0, 0.75, 0.0)
	
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", scale * 0.65, 0.35)
	if body_mesh.material_override is StandardMaterial3D:
		var material := body_mesh.material_override as StandardMaterial3D
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		tween.tween_property(material, "albedo_color:a", 0.0, 0.35)
	if effect_parent != null:
		tween.tween_property(flash, "scale", Vector3(1.6, 1.6, 1.6), 0.35)
		tween.tween_property(flash, "material_override:albedo_color:a", 0.0, 0.35)
	tween.set_parallel(false)
	if effect_parent != null:
		tween.tween_callback(flash.queue_free)
	tween.tween_callback(queue_free)

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

func apply_visual_attachments() -> void:
	clear_visual_attachments()
	var attachments := Node3D.new()
	attachments.name = "VisualAttachments"
	add_child(attachments)

	add_faction_accent_band(attachments)
	match role:
		"Tank":
			add_shield_attachment(attachments)
		"Ranged":
			add_ranged_attachment(attachments)
		"Fighter":
			add_weapon_attachment(attachments)
		_:
			add_weapon_attachment(attachments)

func clear_visual_attachments() -> void:
	var existing := get_node_or_null("VisualAttachments")
	if existing != null:
		existing.queue_free()

func add_faction_accent_band(parent: Node3D) -> void:
	var band := MeshInstance3D.new()
	band.name = "FactionAccentBand"
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.42
	mesh.bottom_radius = 0.42
	mesh.height = 0.07
	mesh.radial_segments = 10
	band.mesh = mesh
	band.position = Vector3(0.0, 0.55, 0.0)
	band.material_override = create_visual_material(get_faction_accent_color())
	parent.add_child(band)

func add_shield_attachment(parent: Node3D) -> void:
	var shield := MeshInstance3D.new()
	shield.name = "ShieldAttachment"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.5, 0.58, 0.08)
	shield.mesh = mesh
	shield.position = Vector3(-0.42, 0.72, 0.34)
	shield.rotation_degrees = Vector3(0.0, -15.0, 0.0)
	shield.material_override = create_visual_material(get_faction_accent_color())
	parent.add_child(shield)

	var boss := MeshInstance3D.new()
	boss.name = "ShieldBoss"
	var boss_mesh := SphereMesh.new()
	boss_mesh.radius = 0.09
	boss_mesh.height = 0.12
	boss_mesh.radial_segments = 8
	boss_mesh.rings = 4
	boss.mesh = boss_mesh
	boss.position = shield.position + Vector3(0.0, 0.02, 0.06)
	boss.material_override = create_visual_material(get_faction_secondary_color())
	parent.add_child(boss)

func add_weapon_attachment(parent: Node3D) -> void:
	var handle := MeshInstance3D.new()
	handle.name = "WeaponHandle"
	var handle_mesh := BoxMesh.new()
	handle_mesh.size = Vector3(0.08, 0.72, 0.08)
	handle.mesh = handle_mesh
	handle.position = Vector3(0.45, 0.68, 0.18)
	handle.rotation_degrees = Vector3(0.0, 0.0, -24.0)
	handle.material_override = create_visual_material(Color(0.22, 0.15, 0.09))
	parent.add_child(handle)

	var blade := MeshInstance3D.new()
	blade.name = "WeaponBlade"
	var blade_mesh := BoxMesh.new()
	blade_mesh.size = Vector3(0.12, 0.32, 0.06)
	blade.mesh = blade_mesh
	blade.position = Vector3(0.58, 1.02, 0.18)
	blade.rotation_degrees = handle.rotation_degrees
	blade.material_override = create_visual_material(get_faction_secondary_color())
	parent.add_child(blade)

func add_ranged_attachment(parent: Node3D) -> void:
	var staff := MeshInstance3D.new()
	staff.name = "BowStaffAttachment"
	var staff_mesh := BoxMesh.new()
	staff_mesh.size = Vector3(0.07, 0.95, 0.07)
	staff.mesh = staff_mesh
	staff.position = Vector3(0.46, 0.78, 0.1)
	staff.rotation_degrees = Vector3(0.0, 0.0, -10.0)
	staff.material_override = create_visual_material(get_faction_accent_color())
	parent.add_child(staff)

	var string := MeshInstance3D.new()
	string.name = "BowStringAttachment"
	var string_mesh := BoxMesh.new()
	string_mesh.size = Vector3(0.035, 0.82, 0.035)
	string.mesh = string_mesh
	string.position = Vector3(0.34, 0.78, 0.1)
	string.rotation_degrees = Vector3(0.0, 0.0, 8.0)
	string.material_override = create_visual_material(Color(0.08, 0.07, 0.06))
	parent.add_child(string)

func get_faction_accent_color() -> Color:
	match faction:
		"Romans":
			return Color(0.68, 0.08, 0.06)
		"Vikings":
			return Color(0.17, 0.25, 0.34)
		"Slavs":
			return Color(0.24, 0.38, 0.2)
		"Mongols":
			return Color(0.68, 0.48, 0.2)
		_:
			return Color(0.42, 0.42, 0.38)

func get_faction_secondary_color() -> Color:
	match faction:
		"Romans":
			return Color(0.78, 0.55, 0.22)
		"Vikings":
			return Color(0.36, 0.42, 0.48)
		"Slavs":
			return Color(0.38, 0.27, 0.14)
		"Mongols":
			return Color(0.86, 0.66, 0.3)
		_:
			return Color(0.55, 0.55, 0.5)

func create_visual_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.72
	return material

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
