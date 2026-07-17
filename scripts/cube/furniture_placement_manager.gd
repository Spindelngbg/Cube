extends Node

## Köpta möbler kan placeras i världen (särskilt på egen tomt).

signal placement_changed
signal placement_mode_changed(active: bool, item_id: String)

const FurnitureKitLibraryScript = preload("res://scripts/assets/furniture_kit_library.gd")
const WorldCollisionBuilderScript = preload("res://scripts/world/world_collision_builder.gd")

const SHOP_FURNITURE: Array[Dictionary] = [
	{"id": "furn_chair", "name": "Stol", "model": "chair", "price": 120, "description": "Enkel stol att sitta på."},
	{"id": "furn_table", "name": "Bord", "model": "table", "price": 280, "description": "Träbord för basen."},
	{"id": "furn_bed", "name": "Säng", "model": "bedSingle", "price": 450, "description": "Sovplats. Kolonister behöver vila."},
	{"id": "furn_sofa", "name": "Soffa", "model": "loungeSofa", "price": 620, "description": "Mjuk soffa — lyx i kuben."},
	{"id": "furn_desk", "name": "Skrivbord", "model": "desk", "price": 380, "description": "Bra plats för planering."},
	{"id": "furn_lamp", "name": "Golvlampa", "model": "lampRoundFloor", "price": 180, "description": "Lyser upp mörka hörn."},
	{"id": "furn_plant", "name": "Krukväxt", "model": "pottedPlant", "price": 90, "description": "Grönt i hemmet."},
	{"id": "furn_bookshelf", "name": "Bokhylla", "model": "bookcaseOpen", "price": 340, "description": "För lore och skräp."},
	{"id": "furn_tv", "name": "TV", "model": "televisionModern", "price": 700, "description": "Koloniens underhållning."},
	{"id": "furn_fridge", "name": "Kylskåp", "model": "kitchenFridge", "price": 550, "description": "Håller ransoner kalla."},
]

var _placements: Array = [] # {item_id, model, pos:[x,y,z], yaw, spawn_id}
var _save_slot := "guest"
var _root: Node3D
var _active_spawn_id := ""
var _placing_item_id := ""
var _ghost: Node3D
var _nodes: Array[Node3D] = []


func _ready() -> void:
	Profile.character_selected.connect(_on_character_selected)
	_on_character_selected()
	set_process(false)


func setup_world(parent: Node3D, spawn_id: String) -> void:
	_active_spawn_id = SpawnPoints.normalize_id(spawn_id)
	if _root != null and is_instance_valid(_root):
		_root.queue_free()
	_nodes.clear()
	_root = Node3D.new()
	_root.name = "PlacedFurniture"
	parent.add_child(_root)
	_cancel_placement()
	_rebuild_visuals()


func get_shop_catalog() -> Array[Dictionary]:
	return SHOP_FURNITURE


func get_furniture_def(item_id: String) -> Dictionary:
	for entry in SHOP_FURNITURE:
		if str(entry.get("id", "")) == item_id:
			return entry
	return {}


func is_furniture(item_id: String) -> bool:
	return not get_furniture_def(item_id).is_empty() or ItemCatalog.get_item_type(item_id) == "furniture"


func is_placing() -> bool:
	return _placing_item_id != ""


func get_placing_item_id() -> String:
	return _placing_item_id


func begin_placement(item_id: String) -> bool:
	if not InventoryManager.has_item(item_id) and not _is_shop_stock(item_id):
		# Tillåt placering om man just köpt till inventory.
		if not InventoryManager.has_item(item_id):
			return false
	if not InventoryManager.has_item(item_id):
		return false
	_placing_item_id = item_id
	_ensure_ghost()
	set_process(true)
	placement_mode_changed.emit(true, item_id)
	QuestManager.story_toast.emit(
		"Placera möbel",
		"Vänsterklick = placera | Högerklick/Esc = avbryt | Scroll = rotera"
	)
	return true


func cancel_placement() -> void:
	_cancel_placement()


func try_buy_and_hold(item_id: String) -> bool:
	var def := get_furniture_def(item_id)
	if def.is_empty():
		return false
	var price := int(def.get("price", 0))
	if InventoryManager.has_item(item_id):
		return begin_placement(item_id)
	if not InventoryManager.spend_mydrillium(price):
		QuestManager.story_toast.emit(
			"Möbelbutik",
			"Du behöver %d %s." % [price, ItemCatalog.currency_symbol()]
		)
		return false
	# Se till att item finns i katalog.
	if ItemCatalog.get_item(item_id).is_empty():
		# Fallback: lagra bara som placement stock via meta inventory id
		pass
	if not InventoryManager.add_item(item_id):
		# Om item saknas i katalog, lagra i intern kö-lista
		InventoryManager.add_mydrillium(price)
		QuestManager.story_toast.emit("Möbelbutik", "Kunde inte lägga möbeln i inventory.")
		return false
	QuestManager.story_toast.emit("Möbelbutik", "%s köpt — placera den nu." % str(def.get("name", item_id)))
	return begin_placement(item_id)


func _process(_delta: float) -> void:
	if not is_placing():
		return
	_update_ghost()


func try_confirm_placement_from_camera(camera: Camera3D, yaw: float) -> bool:
	if not is_placing() or camera == null:
		return false
	var hit := _ray_floor(camera)
	if hit.is_empty():
		# Fallback: placera framför kameran på golvnivå.
		var origin := camera.global_position + (-camera.global_transform.basis.z) * 3.0
		origin.y = SpawnPoints.SPAWN_FOOT_Y
		return _place_at(origin, yaw)
	var pos: Vector3 = hit.position
	pos.y = maxf(pos.y, SpawnPoints.SPAWN_FOOT_Y)
	return _place_at(pos, yaw)


func rotate_ghost(delta_yaw: float) -> void:
	if _ghost:
		_ghost.rotation.y += delta_yaw


func _place_at(world_pos: Vector3, yaw: float) -> bool:
	var item_id := _placing_item_id
	var def := get_furniture_def(item_id)
	var model := str(def.get("model", ""))
	if model == "":
		return false
	if not InventoryManager.has_item(item_id):
		return false
	InventoryManager.remove_item(item_id)
	_placements.append({
		"item_id": item_id,
		"model": model,
		"pos": [world_pos.x, world_pos.y, world_pos.z],
		"yaw": yaw if _ghost == null else _ghost.rotation.y,
		"spawn_id": _active_spawn_id,
	})
	_save()
	_spawn_one(_placements[_placements.size() - 1])
	_cancel_placement()
	placement_changed.emit()
	QuestManager.story_toast.emit("Möbel placerad", "%s står nu i världen." % str(def.get("name", item_id)))
	return true


func _spawn_one(entry: Dictionary) -> void:
	if _root == null:
		return
	if str(entry.get("spawn_id", "")) != _active_spawn_id and _active_spawn_id != "":
		return
	var model := str(entry.get("model", ""))
	var pos_arr: Array = entry.get("pos", [0, 0, 0])
	var pos := Vector3(float(pos_arr[0]), float(pos_arr[1]), float(pos_arr[2]))
	var yaw := float(entry.get("yaw", 0.0))
	var node := FurnitureKitLibraryScript.spawn(_root, model, pos, yaw)
	if node == null:
		return
	node.scale = Vector3.ONE * 1.6
	WorldCollisionBuilderScript.attach_box(node, Vector3(1.2, 1.0, 1.2), Vector3(0.0, 0.5, 0.0))
	_nodes.append(node)


func _rebuild_visuals() -> void:
	for entry in _placements:
		_spawn_one(entry)


func _ensure_ghost() -> void:
	_clear_ghost()
	var def := get_furniture_def(_placing_item_id)
	var model := str(def.get("model", "chair"))
	if _root == null:
		return
	_ghost = FurnitureKitLibraryScript.spawn(_root, model, Vector3.ZERO, 0.0)
	if _ghost:
		_ghost.scale = Vector3.ONE * 1.6
		_set_ghost_material(_ghost)


func _update_ghost() -> void:
	if _ghost == null:
		return
	var game := get_tree().get_first_node_in_group("game_director")
	if game == null or not game.has_method("get_camera"):
		return
	var cam: Camera3D = game.get_camera()
	if cam == null:
		return
	var hit := _ray_floor(cam)
	if hit.is_empty():
		_ghost.visible = false
		return
	_ghost.visible = true
	_ghost.global_position = hit.position


func _ray_floor(camera: Camera3D) -> Dictionary:
	var from := camera.project_ray_origin(camera.get_viewport().get_mouse_position())
	var dir := camera.project_ray_normal(camera.get_viewport().get_mouse_position())
	var to := from + dir * 80.0
	var space := camera.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1
	return space.intersect_ray(query)


func _set_ghost_material(node: Node) -> void:
	if node is MeshInstance3D:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.3, 0.9, 0.5, 0.45)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.emission_enabled = true
		mat.emission = Color(0.2, 0.8, 0.4)
		mat.emission_energy_multiplier = 0.3
		(node as MeshInstance3D).material_override = mat
	for child in node.get_children():
		_set_ghost_material(child)


func _cancel_placement() -> void:
	_placing_item_id = ""
	_clear_ghost()
	set_process(false)
	placement_mode_changed.emit(false, "")


func _clear_ghost() -> void:
	if _ghost != null and is_instance_valid(_ghost):
		_ghost.queue_free()
	_ghost = null


func _is_shop_stock(item_id: String) -> bool:
	return not get_furniture_def(item_id).is_empty()


func _on_character_selected() -> void:
	var slot := Profile.active_character_id if Profile.active_character_id != "" else Auth.username
	if slot.strip_edges() == "":
		slot = "guest"
	_save_slot = slot
	_load()


func _save_path() -> String:
	return "user://furniture_placements_%s.json" % _save_slot


func _load() -> void:
	_placements.clear()
	if not FileAccess.file_exists(_save_path()):
		return
	var file := FileAccess.open(_save_path(), FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		_placements = parsed.get("placements", [])


func _save() -> void:
	var file := FileAccess.open(_save_path(), FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({"placements": _placements}, "\t"))
