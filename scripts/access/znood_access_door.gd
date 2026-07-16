class_name ZnoodAccessDoor
extends Node3D

const GameSfxScript = preload("res://scripts/audio/game_sfx.gd")
const RpgAudioLibraryScript = preload("res://scripts/audio/rpg_audio_library.gd")

signal door_opened(door_id: String)

@export var door_id := ""
@export var prompt_locked := "Stämpla Znood [E]"
@export var prompt_open := "Dörr öppen"

var _locked := true
var _opening := false
var _player_inside := false

var _blocker: StaticBody3D
var _leaf: Node3D
var _reader_area: Area3D
var _status_label: Label3D


func _ready() -> void:
	add_to_group("znood_door")


func setup(
	block_size: Vector3,
	leaf_axis: Vector3 = Vector3(0, 1, 0),
	open_angle_deg: float = -92.0
) -> void:
	_build_geometry(block_size, leaf_axis, open_angle_deg)
	_reader_area.body_entered.connect(_on_reader_entered)
	_reader_area.body_exited.connect(_on_reader_exited)


func is_locked() -> bool:
	return _locked


func is_player_nearby() -> bool:
	return _player_inside


func get_prompt() -> String:
	if _locked:
		return prompt_locked
	return prompt_open


func can_stamp(player: Node3D) -> bool:
	return _locked and _player_inside and _reader_in_range(player)


func try_stamp(player: Node3D) -> bool:
	if not can_stamp(player):
		return false
	if not player.has_method("stamp_znood_at"):
		return false
	player.stamp_znood_at(self)
	return true


func unlock_from_stamp(_player_id: int) -> void:
	if not _locked or _opening:
		return
	if multiplayer.multiplayer_peer == null:
		_do_unlock()
	else:
		_sync_unlock.rpc(door_id)


func _do_unlock() -> void:
	if not _locked:
		return
	_locked = false
	_opening = true
	_update_status_label()
	GameSfxScript.play_3d_varied(self, global_position + Vector3(0.0, 1.2, 0.0), RpgAudioLibraryScript.door_open())
	GameSfxScript.play_3d_varied(
		self,
		global_position + Vector3(0.0, 1.8, 0.0),
		RpgAudioLibraryScript.door_creak(),
		Vector2(-14.0, -9.0),
		Vector2(0.88, 1.02)
	)
	_open_leaf()
	door_opened.emit(door_id)


func _open_leaf() -> void:
	if _blocker:
		_blocker.collision_layer = 0
	if _leaf == null:
		_opening = false
		return
	var tween := create_tween()
	tween.tween_property(_leaf, "rotation_degrees:y", -92.0, 0.65)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func() -> void:
		_opening = false
	)


func _reader_in_range(player: Node3D) -> bool:
	if _reader_area == null:
		return false
	var bodies := _reader_area.get_overlapping_bodies()
	return player in bodies


func _build_geometry(block_size: Vector3, _leaf_axis: Vector3, _open_angle_deg: float) -> void:
	var frame := Node3D.new()
	frame.name = "Frame"
	add_child(frame)

	var frame_mat := StandardMaterial3D.new()
	frame_mat.albedo_color = Color(0.22, 0.24, 0.28)
	frame_mat.metallic = 0.45
	frame_mat.roughness = 0.55

	var left_frame := _box(frame, Vector3(0.14, block_size.y, block_size.z), Vector3(-block_size.x * 0.5 + 0.07, block_size.y * 0.5, 0.0), frame_mat)
	left_frame.name = "FrameLeft"
	var right_frame := _box(frame, Vector3(0.14, block_size.y, block_size.z), Vector3(block_size.x * 0.5 - 0.07, block_size.y * 0.5, 0.0), frame_mat)
	right_frame.name = "FrameRight"
	var top_frame := _box(frame, Vector3(block_size.x, 0.14, block_size.z), Vector3(0.0, block_size.y - 0.07, 0.0), frame_mat)
	top_frame.name = "FrameTop"

	_blocker = StaticBody3D.new()
	_blocker.name = "DoorBlocker"
	_blocker.collision_layer = 1
	add_child(_blocker)
	var blocker_shape := CollisionShape3D.new()
	var blocker_box := BoxShape3D.new()
	blocker_box.size = Vector3(block_size.x - 0.2, block_size.y - 0.1, 0.22)
	blocker_shape.shape = blocker_box
	blocker_shape.position = Vector3(0.0, block_size.y * 0.5, 0.0)
	_blocker.add_child(blocker_shape)

	_leaf = Node3D.new()
	_leaf.name = "DoorLeaf"
	_leaf.position = Vector3(-block_size.x * 0.5 + 0.12, 0.0, 0.0)
	add_child(_leaf)
	var leaf_mesh := MeshInstance3D.new()
	var leaf_box := BoxMesh.new()
	leaf_box.size = Vector3(block_size.x - 0.24, block_size.y - 0.16, 0.12)
	leaf_mesh.mesh = leaf_box
	leaf_mesh.position = Vector3((block_size.x - 0.24) * 0.5, block_size.y * 0.5, 0.0)
	var leaf_mat := StandardMaterial3D.new()
	leaf_mat.albedo_color = Color(0.32, 0.34, 0.38)
	leaf_mat.metallic = 0.35
	leaf_mat.roughness = 0.62
	leaf_mesh.material_override = leaf_mat
	_leaf.add_child(leaf_mesh)

	_reader_area = Area3D.new()
	_reader_area.name = "ZnoodReader"
	_reader_area.collision_layer = 0
	_reader_area.collision_mask = 1
	_reader_area.position = Vector3(0.0, 1.35, block_size.z * 0.5 + 0.22)
	add_child(_reader_area)
	var reader_shape := CollisionShape3D.new()
	var reader_box := BoxShape3D.new()
	reader_box.size = Vector3(1.0, 1.1, 0.85)
	reader_shape.shape = reader_box
	_reader_area.add_child(reader_shape)

	var panel := MeshInstance3D.new()
	panel.name = "ReaderPanel"
	var panel_mesh := BoxMesh.new()
	panel_mesh.size = Vector3(0.48, 0.62, 0.08)
	panel.mesh = panel_mesh
	panel.position = Vector3(0.0, 0.0, 0.0)
	var panel_mat := StandardMaterial3D.new()
	panel_mat.albedo_color = Color(0.08, 0.1, 0.12)
	panel_mat.metallic = 0.6
	panel_mat.emission_enabled = true
	panel_mat.emission = Color(0.2, 0.85, 0.45)
	panel_mat.emission_energy_multiplier = 0.25
	panel.material_override = panel_mat
	_reader_area.add_child(panel)

	_status_label = Label3D.new()
	_status_label.font_size = 20
	_status_label.position = Vector3(0.0, 0.42, 0.1)
	_status_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_reader_area.add_child(_status_label)
	_update_status_label()


func _update_status_label() -> void:
	if _status_label == null:
		return
	if _locked:
		_status_label.text = "ZNood-läsare\nLÅST"
		_status_label.modulate = Color(0.95, 0.35, 0.32)
	else:
		_status_label.text = "ZNood-läsare\nÖPPEN"
		_status_label.modulate = Color(0.45, 0.95, 0.42)


func _box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mesh_inst := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_inst.mesh = mesh
	mesh_inst.position = pos
	mesh_inst.material_override = mat
	parent.add_child(mesh_inst)
	return mesh_inst


func _on_reader_entered(body: Node) -> void:
	if body is CharacterBody3D and body.is_multiplayer_authority():
		_player_inside = true


func _on_reader_exited(body: Node) -> void:
	if body is CharacterBody3D and body.is_multiplayer_authority():
		_player_inside = false


@rpc("any_peer", "call_local", "reliable")
func _sync_unlock(sync_door_id: String) -> void:
	if sync_door_id != door_id or not _locked:
		return
	_do_unlock()