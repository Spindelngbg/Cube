class_name WeaponShopOwner
extends Node3D

const WeaponShopCatalogScript = preload("res://scripts/shops/weapon_shop_catalog.gd")
const CharacterKitLibraryScript = preload("res://scripts/assets/character_kit_library.gd")

const PROMPT := "Prata med Stål-Sven [E]"
const APRON_COLOR := Color(0.9, 0.35, 0.22)
const SHIRT_COLOR := Color(0.22, 0.24, 0.3)

var _player_inside := false
var _voice_player: AudioStreamPlayer3D
var _name_label: Label3D
var _interact_area: Area3D


func _ready() -> void:
	add_to_group("weapon_shop_owner")
	_build_owner()
	_build_interact_area()
	_build_voice()


func get_voice_player() -> AudioStreamPlayer3D:
	return _voice_player


func is_player_nearby() -> bool:
	return _player_inside


func get_prompt() -> String:
	return PROMPT


func try_open_dialog(dialog_ui: WeaponShopDialogUI) -> bool:
	if dialog_ui == null:
		return false
	dialog_ui.open(self)
	return true


func _build_voice() -> void:
	_voice_player = AudioStreamPlayer3D.new()
	_voice_player.name = "Voice"
	_voice_player.bus = &"Sfx"
	_voice_player.max_distance = 22.0
	_voice_player.position = Vector3(0.0, 1.45, 0.0)
	add_child(_voice_player)


func _build_interact_area() -> void:
	_interact_area = Area3D.new()
	_interact_area.name = "InteractArea"
	_interact_area.collision_layer = 0
	_interact_area.collision_mask = 1
	_interact_area.position = Vector3(0.0, 1.0, 0.0)
	add_child(_interact_area)

	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(3.2, 2.6, 3.2)
	shape.shape = box
	_interact_area.add_child(shape)

	_interact_area.body_entered.connect(_on_body_entered)
	_interact_area.body_exited.connect(_on_body_exited)


func _build_owner() -> void:
	var counter := MeshInstance3D.new()
	var counter_mesh := BoxMesh.new()
	counter_mesh.size = Vector3(3.6, 1.0, 1.2)
	counter.mesh = counter_mesh
	counter.position = Vector3(0.0, 0.5, 0.55)
	var counter_mat := StandardMaterial3D.new()
	counter_mat.albedo_color = Color(0.28, 0.22, 0.18)
	counter_mat.roughness = 0.72
	counter.material_override = counter_mat
	add_child(counter)

	var pivot := Node3D.new()
	pivot.name = "ModelPivot"
	pivot.position = Vector3(0.0, 0.0, -0.15)
	add_child(pivot)

	var model := CharacterKitLibraryScript.spawn(pivot, "character-m", Vector3.ZERO, PI, 1.02)
	if model != null:
		CharacterKitLibraryScript.apply_tint(model, SHIRT_COLOR)

	var apron := MeshInstance3D.new()
	var apron_mesh := BoxMesh.new()
	apron_mesh.size = Vector3(0.55, 0.62, 0.08)
	apron.mesh = apron_mesh
	apron.position = Vector3(0.0, 1.02, 0.22)
	var apron_mat := StandardMaterial3D.new()
	apron_mat.albedo_color = APRON_COLOR
	apron.material_override = apron_mat
	pivot.add_child(apron)

	_name_label = Label3D.new()
	_name_label.text = WeaponShopCatalogScript.OWNER_NAME
	_name_label.font_size = 34
	_name_label.modulate = APRON_COLOR.lightened(0.15)
	_name_label.outline_modulate = Color(0.08, 0.08, 0.1, 0.95)
	_name_label.position = Vector3(0.0, 2.15, 0.0)
	_name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(_name_label)


func _on_body_entered(body: Node) -> void:
	if body is CharacterBody3D and body.is_multiplayer_authority():
		_player_inside = true


func _on_body_exited(body: Node) -> void:
	if body is CharacterBody3D and body.is_multiplayer_authority():
		_player_inside = false