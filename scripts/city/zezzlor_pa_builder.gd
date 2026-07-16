class_name ZezzlorPaBuilder
extends RefCounted

const ZezzlorPaManagerScript = preload("res://scripts/city/zezzlor_pa_manager.gd")
const ZezzlorPaSpeakerScript = preload("res://scripts/city/zezzlor_pa_speaker.gd")

const CORNER_INSET := 3.8
const BASE_HEIGHT := 10.5


static func build(city_root: Node3D) -> ZezzlorPaManager:
	var manager := ZezzlorPaManagerScript.new()
	manager.name = "ZezzlorPaSystem"
	city_root.add_child(manager)

	var extent: Dictionary = DcZoneCatalog.grid_extent()
	for x in range(extent.x_min, extent.x_max + 1):
		for z in range(extent.z_min, extent.z_max + 1):
			var cell := Vector2i(x, z)
			if _skip_cell(cell):
				continue
			var spec: Dictionary = DcZoneCatalog.classify_cell(cell)
			if str(spec.get("kit", "")) == "roads":
				continue
			_place_block_speakers(manager, _cell_origin(cell), cell)

	_place_extra_speakers(manager)
	return manager


static func _skip_cell(cell: Vector2i) -> bool:
	if cell in DcZoneCatalog.mall_cells():
		return true
	if cell == Vector2i(-3, 0) or cell == Vector2i(0, 0) or cell == Vector2i(-6, 0):
		return true
	return cell == Vector2i(-4, -3)


static func _place_block_speakers(manager: ZezzlorPaManager, origin: Vector3, cell: Vector2i) -> void:
	var block := DcZoneCatalog.BLOCK_M
	var height := BASE_HEIGHT + float((cell.x + cell.y + 3) % 4) * 1.35
	var corners: Array[Vector3] = [
		Vector3(CORNER_INSET, height, CORNER_INSET),
		Vector3(block - CORNER_INSET, height, CORNER_INSET),
		Vector3(CORNER_INSET, height, block - CORNER_INSET),
		Vector3(block - CORNER_INSET, height, block - CORNER_INSET),
	]
	var yaws: Array[float] = [PI * 0.75, PI * 0.25, -PI * 0.25, -PI * 0.75]

	var rng := RandomNumberGenerator.new()
	rng.seed = hash("zezzlor_pa_%d_%d" % [cell.x, cell.y])
	var first := rng.randi() % corners.size()
	var second := (first + 1 + rng.randi() % 2) % corners.size()

	for idx in [first, second]:
		var speaker := ZezzlorPaSpeakerScript.mount(
			manager,
			{
				"position": origin + corners[idx],
				"rotation_y": yaws[idx],
				"seed": hash("%d_%d_%d" % [cell.x, cell.y, idx]),
			}
		)
		manager.register_speaker(speaker)


static func _place_extra_speakers(manager: ZezzlorPaManager) -> void:
	var spawn := _cell_origin(Vector2i(0, 0)) + Vector3(
		DcZoneCatalog.BLOCK_M * 0.5,
		0.0,
		DcZoneCatalog.BLOCK_M * 0.5
	)
	var extras: Array[Dictionary] = [
		{"position": spawn + Vector3(16.0, 12.0, -10.0), "rotation_y": -PI * 0.5},
		{"position": spawn + Vector3(-14.0, 11.5, 12.0), "rotation_y": PI},
		{"position": _cell_origin(Vector2i(1, 0)) + Vector3(8.0, 13.0, 20.0), "rotation_y": 0.0},
		{"position": _cell_origin(Vector2i(-2, 3)) + Vector3(30.0, 12.5, 8.0), "rotation_y": PI * 0.5},
	]
	for i in range(extras.size()):
		var cfg: Dictionary = extras[i]
		cfg["seed"] = hash("zezzlor_pa_extra_%d" % i)
		manager.register_speaker(ZezzlorPaSpeakerScript.mount(manager, cfg))


static func _cell_origin(cell: Vector2i) -> Vector3:
	return Vector3(
		float(cell.x) * DcZoneCatalog.BLOCK_M,
		0.0,
		float(cell.y) * DcZoneCatalog.BLOCK_M
	)