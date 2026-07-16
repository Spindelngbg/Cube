class_name NpcDialogueBark
extends RefCounted

const SuperDialogueAudioLibraryScript = preload("res://scripts/audio/super_dialogue_audio_library.gd")
const GameSfxScript = preload("res://scripts/audio/game_sfx.gd")

const NPC_GROUPS := [
	"world_npc",
	"gleazer_npc",
	"allmakare_npc",
	"pedestrian_npc",
	"src_guard",
	"help_robot",
	"world_monster",
	"delivery_bot",
	"zezzla_bot",
]


static func play_for_npc(npc: Node3D, category: String, voice: String = "", index: int = -1) -> void:
	if npc == null or not is_instance_valid(npc):
		return
	var picked_voice := voice if voice != "" else _voice_for_entity(npc)
	_play(npc, npc.global_position + Vector3(0.0, 1.55, 0.0), category, picked_voice, index)


static func play_for_id(npc_id: String, category: String, voice: String = "", index: int = -1) -> void:
	var npc := find_by_npc_id(npc_id)
	if npc != null:
		play_for_npc(npc, category, voice, index)
		return
	var picked_voice := voice if voice != "" else SuperDialogueAudioLibraryScript.voice_for_id(npc_id)
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.current_scene == null:
		return
	_play(tree.current_scene, Vector3.ZERO, category, picked_voice, index)


static func play_at(
	parent: Node,
	world_pos: Vector3,
	category: String,
	voice: String = "",
	index: int = -1
) -> void:
	if parent == null:
		return
	var picked_voice := voice if voice != "" else "ian"
	_play(parent, world_pos + Vector3(0.0, 1.55, 0.0), category, picked_voice, index)


static func find_by_npc_id(npc_id: String) -> Node3D:
	if npc_id.strip_edges() == "":
		return null
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	for group_name in NPC_GROUPS:
		for node in tree.get_nodes_in_group(group_name):
			if not is_instance_valid(node):
				continue
			if str(node.get_meta("npc_id", "")) == npc_id:
				return node as Node3D
	return null


static func _voice_for_entity(entity: Node) -> String:
	if entity.has_meta("dialogue_voice"):
		return str(entity.get_meta("dialogue_voice"))
	var id := str(entity.get_meta("npc_id", entity.name))
	return SuperDialogueAudioLibraryScript.voice_for_id(id)


static func _play(
	parent: Node,
	world_pos: Vector3,
	category: String,
	voice: String,
	index: int
) -> void:
	var stream := SuperDialogueAudioLibraryScript.bark(category, voice, index)
	if stream == null:
		return
	GameSfxScript.play_3d_varied(
		parent,
		world_pos,
		stream,
		Vector2(-9.0, -4.0),
		Vector2(0.94, 1.06)
	)