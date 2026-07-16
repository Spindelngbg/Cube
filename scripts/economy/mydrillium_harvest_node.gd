class_name MydrilliumHarvestNode
extends Area3D

const MydrilliumMaterialCatalogScript = preload(
	"res://scripts/economy/mydrillium_material_catalog.gd"
)
const GameSfxScript = preload("res://scripts/audio/game_sfx.gd")
const RpgAudioLibraryScript = preload("res://scripts/audio/rpg_audio_library.gd")

@export var material_id := "raw_mydrillium_ore"
@export var harvest_amount := 1
@export var respawn_seconds := 42.0
@export var prompt_text := "Hacka malm [E]"

var _player_inside := false
var _depleted := false
var _respawn_timer := 0.0


func _ready() -> void:
	add_to_group("mydrillium_harvest")
	collision_layer = 0
	collision_mask = 1
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_build_visual()
	set_process(true)


func _process(delta: float) -> void:
	if not _depleted:
		return
	_respawn_timer -= delta
	if _respawn_timer <= 0.0:
		_depleted = false
		visible = true
		monitoring = true
		monitorable = true


func is_player_nearby() -> bool:
	return _player_inside and not _depleted


func get_prompt() -> String:
	if _depleted:
		return ""
	return prompt_text


func try_harvest() -> bool:
	if _depleted or material_id == "":
		return false
	var got := MydrilliumEconomyManager.harvest_from_node(material_id, harvest_amount)
	if got <= 0:
		return false
	GameSfxScript.play_3d_varied(
		self,
		global_position + Vector3(0.0, 0.6, 0.0),
		RpgAudioLibraryScript.pickup_item()
	)
	QuestManager.story_toast.emit(
		"Mineral insamlad",
		"+%d %s"
		% [got, MydrilliumMaterialCatalogScript.get_display_name(material_id)]
	)
	var game := get_tree().get_first_node_in_group("game_director")
	if game != null and game.has_method("get_local_player"):
		var player: Node3D = game.get_local_player()
		if player != null:
			ArrivalQuestManager.notify_mineral_collected(player.global_position)
	_depleted = true
	_respawn_timer = respawn_seconds
	visible = false
	monitoring = false
	monitorable = false
	return true


func _build_visual() -> void:
	var color := Color(0.22, 0.88, 0.42) if material_id == "raw_mydrillium_ore" else Color(0.55, 0.62, 0.72)
	if material_id == "contaminated_ore":
		color = Color(0.78, 0.22, 0.92)
	elif material_id == "tech_scrap":
		color = Color(0.72, 0.58, 0.34)
	elif material_id == "mydrillium_sludge":
		color = Color(0.18, 0.55, 0.68)

	var rock := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(1.1, 0.85, 1.0)
	rock.mesh = mesh
	rock.position = Vector3(0.0, 0.42, 0.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.35
	rock.material_override = mat
	add_child(rock)

	var label := Label3D.new()
	label.text = MydrilliumMaterialCatalogScript.get_display_name(material_id)
	label.font_size = 20
	label.modulate = color.lightened(0.15)
	label.position = Vector3(0.0, 1.2, 0.0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)

	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.8, 1.6, 1.8)
	shape.shape = box
	shape.position = Vector3(0.0, 0.7, 0.0)
	add_child(shape)


func _on_body_entered(body: Node) -> void:
	if body is CharacterBody3D and body.is_multiplayer_authority():
		_player_inside = true


func _on_body_exited(body: Node) -> void:
	if body is CharacterBody3D and body.is_multiplayer_authority():
		_player_inside = false