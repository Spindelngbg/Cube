class_name ZnoodDevice
extends Node3D

const GameSfxScript = preload("res://scripts/audio/game_sfx.gd")
const RpgAudioLibraryScript = preload("res://scripts/audio/rpg_audio_library.gd")

## Kolonisternas personliga åtkomststämpel — sitter i vänster hand närmast ansiktet.
## Fullständig implementation är avancerad; se data/todos/znood_todo.md.

const STAMP_DURATION := 0.42

var _root: Node3D
var _face_plate: MeshInstance3D
var _ring: MeshInstance3D
var _label: Label3D
var _stamping := false
var _idle_pulse := 0.0
var _screen_active := false
var _screen_panel: MeshInstance3D


func _ready() -> void:
	_build_visual()
	# Znood-modellen ska inte synas på spelaren (funktion finns kvar för stämpling/UI).
	visible = false
	set_process(false)
	var znood := RuntimeGlobals.znood()
	if znood and znood.has_signal("device_open_changed"):
		znood.device_open_changed.connect(_on_device_open_changed)


func _process(delta: float) -> void:
	if _stamping:
		return
	_idle_pulse += delta * 2.4
	var pulse := 0.35 + sin(_idle_pulse) * 0.12
	if _screen_active:
		pulse = 1.1 + sin(_idle_pulse * 3.2) * 0.25
	if _ring and _ring.material_override is StandardMaterial3D:
		(_ring.material_override as StandardMaterial3D).emission_energy_multiplier = pulse
	_update_screen_glow()


func get_stamp_origin() -> Vector3:
	return global_position


func is_ready() -> bool:
	return not _stamping


func play_stamp(target_global: Vector3) -> void:
	if _stamping:
		return
	_stamping = true
	var start_pos := position
	var start_rot := rotation
	var local_target := to_local(target_global)
	var reach := local_target.normalized() * 0.18
	reach.y = lerpf(start_pos.y, local_target.y, 0.35)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position", start_pos + reach, STAMP_DURATION * 0.45)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "rotation", start_rot + Vector3(0.18, 0.22, -0.35), STAMP_DURATION * 0.45)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_pulse_stamp_ring()
	GameSfxScript.play_3d_varied(self, global_position, RpgAudioLibraryScript.stamp())
	tween.chain()
	tween.set_parallel(true)
	tween.tween_property(self, "position", start_pos, STAMP_DURATION * 0.55)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "rotation", start_rot, STAMP_DURATION * 0.55)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.chain().tween_callback(func() -> void:
		_stamping = false
	)


func _build_visual() -> void:
	_root = Node3D.new()
	_root.name = "ZnoodVisual"
	add_child(_root)

	var body := MeshInstance3D.new()
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(0.11, 0.05, 0.14)
	body.mesh = body_mesh
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = Color(0.16, 0.18, 0.22)
	body_mat.metallic = 0.82
	body_mat.roughness = 0.28
	body.material_override = body_mat
	_root.add_child(body)

	_face_plate = MeshInstance3D.new()
	var plate_mesh := CylinderMesh.new()
	plate_mesh.top_radius = 0.045
	plate_mesh.bottom_radius = 0.045
	plate_mesh.height = 0.018
	_face_plate.mesh = plate_mesh
	_face_plate.rotation_degrees = Vector3(90, 0, 0)
	_face_plate.position = Vector3(0.0, 0.0, 0.08)
	var plate_mat := StandardMaterial3D.new()
	plate_mat.albedo_color = Color(0.55, 0.92, 0.38)
	plate_mat.metallic = 0.55
	plate_mat.emission_enabled = true
	plate_mat.emission = Color(0.45, 0.95, 0.32)
	plate_mat.emission_energy_multiplier = 0.55
	_face_plate.material_override = plate_mat
	_root.add_child(_face_plate)

	_ring = MeshInstance3D.new()
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 0.05
	ring_mesh.outer_radius = 0.062
	ring_mesh.rings = 12
	ring_mesh.ring_segments = 24
	_ring.mesh = ring_mesh
	_ring.rotation_degrees = Vector3(90, 0, 0)
	_ring.position = Vector3(0.0, 0.0, 0.075)
	var ring_mat := StandardMaterial3D.new()
	ring_mat.albedo_color = Color(0.2, 0.75, 0.95)
	ring_mat.metallic = 0.7
	ring_mat.emission_enabled = true
	ring_mat.emission = Color(0.25, 0.82, 1.0)
	ring_mat.emission_energy_multiplier = 0.35
	_ring.material_override = ring_mat
	_root.add_child(_ring)

	_label = Label3D.new()
	_label.text = "Znood"
	_label.font_size = 18
	_label.modulate = Color(0.72, 0.95, 0.82)
	_label.outline_modulate = Color(0.04, 0.08, 0.06, 0.95)
	_label.position = Vector3(0.0, 0.09, 0.0)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(_label)

	_screen_panel = MeshInstance3D.new()
	var screen_mesh := QuadMesh.new()
	screen_mesh.size = Vector2(0.07, 0.045)
	_screen_panel.mesh = screen_mesh
	_screen_panel.position = Vector3(0.0, 0.0, 0.092)
	var screen_mat := StandardMaterial3D.new()
	screen_mat.albedo_color = Color(0.04, 0.12, 0.08)
	screen_mat.emission_enabled = true
	screen_mat.emission = Color(0.2, 0.95, 0.45)
	screen_mat.emission_energy_multiplier = 0.0
	screen_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_screen_panel.material_override = screen_mat
	_root.add_child(_screen_panel)


func _on_device_open_changed(open: bool) -> void:
	_screen_active = open
	_update_screen_glow()
	if _label:
		_label.text = "Znood OS" if open else "Znood"


func _update_screen_glow() -> void:
	if _face_plate and _face_plate.material_override is StandardMaterial3D:
		var plate_mat := _face_plate.material_override as StandardMaterial3D
		plate_mat.emission_energy_multiplier = 1.35 if _screen_active else 0.55
	if _screen_panel and _screen_panel.material_override is StandardMaterial3D:
		var screen_mat := _screen_panel.material_override as StandardMaterial3D
		screen_mat.emission_energy_multiplier = 1.45 if _screen_active else 0.0


func _pulse_stamp_ring() -> void:
	if _ring == null or not (_ring.material_override is StandardMaterial3D):
		return
	var mat := _ring.material_override as StandardMaterial3D
	var tween := create_tween()
	tween.tween_property(mat, "emission_energy_multiplier", 2.2, STAMP_DURATION * 0.25)
	tween.tween_property(mat, "emission_energy_multiplier", 0.35, STAMP_DURATION * 0.75)