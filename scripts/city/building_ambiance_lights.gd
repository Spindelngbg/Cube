class_name BuildingAmbianceLights
extends RefCounted

## Fasadlampor på hus + hängande ljusslingor mellan hus (bara meshar, få/inga realtidsljus).

const GlesPerformanceScript = preload("res://scripts/rendering/gles_performance.gd")

static var _bulb_mesh: SphereMesh
static var _fixture_mesh: BoxMesh
static var _cable_mesh: BoxMesh
static var _warm_mat: StandardMaterial3D
static var _cable_mat: StandardMaterial3D
static var _bulb_mat: StandardMaterial3D


static func decorate_building(
	zone_root: Node3D,
	center: Vector3,
	rotation_y: float,
	scale_factor: float,
	warm_color: Color = Color(1.0, 0.82, 0.45)
) -> void:
	_ensure_shared()
	var half := scale_factor * 0.42 + 0.35
	var lamp_y := clampf(scale_factor * 0.55, 3.2, 7.5)
	var root := Node3D.new()
	root.name = "BuildingAmbiance"
	zone_root.add_child(root)

	# 2–3 fasadlampor runt huset (inte i vägbanan).
	var faces := 2 if GlesPerformanceScript.is_active() else 3
	for i in faces:
		var ang := rotation_y + float(i) * (TAU / float(faces)) + 0.35
		var dir := Vector3(sin(ang), 0.0, cos(ang))
		var pos := center + dir * half + Vector3(0.0, lamp_y, 0.0)
		_add_wall_lamp(root, pos, dir, warm_color)

	# Korta utstickande "veranda"-slingor från fasaden utåt (hemtrevligt).
	if not GlesPerformanceScript.is_active() or hash(str(center)) % 3 == 0:
		var front := Vector3(sin(rotation_y), 0.0, cos(rotation_y))
		var a := center + front * (half * 0.2) + Vector3(0.0, lamp_y + 0.6, 0.0)
		var b := center + front * (half + 2.8) + Vector3(0.0, lamp_y - 0.4, 0.0)
		_add_string_lights(root, a, b, warm_color, 5)


static func hang_between_buildings(
	parent: Node3D,
	from_pos: Vector3,
	to_pos: Vector3,
	warm_color: Color = Color(1.0, 0.78, 0.4)
) -> void:
	_ensure_shared()
	var a := from_pos + Vector3(0.0, 5.5, 0.0)
	var b := to_pos + Vector3(0.0, 5.5, 0.0)
	var dist := a.distance_to(b)
	if dist < 8.0 or dist > 55.0:
		return
	var bulbs := 6 if GlesPerformanceScript.is_active() else 10
	_add_string_lights(parent, a, b, warm_color, bulbs)


static func _add_wall_lamp(parent: Node3D, pos: Vector3, outward: Vector3, color: Color) -> void:
	var fixture := MeshInstance3D.new()
	fixture.mesh = _fixture_mesh
	fixture.position = pos
	# Peka utåt från väggen
	if outward.length_squared() > 0.001:
		fixture.look_at(pos + outward.normalized(), Vector3.UP)
	fixture.material_override = _warm_mat
	fixture.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	fixture.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	_cull(fixture, 55.0)
	parent.add_child(fixture)

	var bulb := MeshInstance3D.new()
	bulb.mesh = _bulb_mesh
	bulb.position = pos + outward.normalized() * 0.18 + Vector3(0.0, -0.12, 0.0)
	bulb.material_override = _bulb_mat
	bulb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	bulb.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	_cull(bulb, 55.0)
	parent.add_child(bulb)

	# Mycket sparsam realtidslampa — bara ibland, kort räckvidd.
	if not GlesPerformanceScript.is_active() and hash(str(pos)) % 4 == 0:
		var lite := OmniLight3D.new()
		lite.position = bulb.position
		lite.light_color = color
		lite.light_energy = 0.55
		lite.omni_range = 6.5
		lite.shadow_enabled = false
		parent.add_child(lite)


static func _add_string_lights(
	parent: Node3D,
	a: Vector3,
	b: Vector3,
	color: Color,
	bulb_count: int
) -> void:
	var root := Node3D.new()
	root.name = "HangingLights"
	parent.add_child(root)

	var mid := (a + b) * 0.5
	# Sänkt mitt = hängande båge
	mid.y -= minf(a.distance_to(b) * 0.08, 1.6)

	# Kabel (tunn box längs bågen, ungefärlig)
	var cable := MeshInstance3D.new()
	cable.mesh = _cable_mesh
	var span := b - a
	var length := span.length()
	cable.position = mid
	if span.length_squared() > 0.001:
		cable.look_at(b, Vector3.UP)
	cable.scale = Vector3(0.04, 0.04, length / 2.0)
	cable.material_override = _cable_mat
	cable.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_cull(cable, 60.0)
	root.add_child(cable)

	for i in bulb_count:
		var t := float(i + 1) / float(bulb_count + 1)
		# Kvadratisk sänkning för båge
		var p := a.lerp(b, t)
		p.y = lerpf(a.y, b.y, t) - sin(t * PI) * minf(length * 0.1, 1.8)
		var bulb := MeshInstance3D.new()
		bulb.mesh = _bulb_mesh
		bulb.position = p
		bulb.scale = Vector3.ONE * 0.85
		bulb.material_override = _bulb_mat
		bulb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		bulb.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
		_cull(bulb, 50.0)
		root.add_child(bulb)


static func _cull(mi: MeshInstance3D, end_m: float) -> void:
	mi.visibility_range_begin = 0.0
	mi.visibility_range_end = end_m
	mi.visibility_range_end_margin = 10.0
	mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF


static func _ensure_shared() -> void:
	if _bulb_mesh == null:
		_bulb_mesh = SphereMesh.new()
		_bulb_mesh.radius = 0.11
		_bulb_mesh.height = 0.22
		_bulb_mesh.radial_segments = 8
		_bulb_mesh.rings = 4
	if _fixture_mesh == null:
		_fixture_mesh = BoxMesh.new()
		_fixture_mesh.size = Vector3(0.28, 0.14, 0.22)
	if _cable_mesh == null:
		_cable_mesh = BoxMesh.new()
		_cable_mesh.size = Vector3(1.0, 1.0, 1.0)
	if _warm_mat == null:
		_warm_mat = StandardMaterial3D.new()
		_warm_mat.albedo_color = Color(0.35, 0.28, 0.18)
		_warm_mat.metallic = 0.4
		_warm_mat.roughness = 0.55
	if _cable_mat == null:
		_cable_mat = StandardMaterial3D.new()
		_cable_mat.albedo_color = Color(0.12, 0.1, 0.08)
		_cable_mat.roughness = 0.85
	if _bulb_mat == null:
		_bulb_mat = StandardMaterial3D.new()
		_bulb_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_bulb_mat.albedo_color = Color(1.0, 0.88, 0.55)
		_bulb_mat.emission_enabled = true
		_bulb_mat.emission = Color(1.0, 0.8, 0.35)
		_bulb_mat.emission_energy_multiplier = 1.4
