extends Node

## Visar stora 3D-pilar ovanför POI:er och blinkande markörer på minimap
## under de första 10 minuterna i en koloni-session.

const DURATION_SEC := 600.0
const PoiGuideArrow3DScript = preload("res://scripts/world/poi_guide_arrow_3d.gd")

var active := false
var time_remaining := 0.0

var _arrows_root: Node3D
var _blink_phase := 0.0


func _ready() -> void:
	var znood := RuntimeGlobals.znood()
	if znood:
		znood.waypoint_changed.connect(func(_a, _b) -> void: pass)


func _process(delta: float) -> void:
	if not active:
		return
	time_remaining = maxf(0.0, time_remaining - delta)
	_blink_phase += delta * 4.5
	if time_remaining <= 0.0:
		stop_guide()
		return
	_sync_arrows()


func begin_colony_session(game_root: Node3D, spawn_id: String) -> void:
	stop_guide()
	if game_root == null or spawn_id == "":
		return
	active = true
	time_remaining = DURATION_SEC
	_arrows_root = Node3D.new()
	_arrows_root.name = "PoiGuideArrows"
	game_root.add_child(_arrows_root)
	call_deferred("_rebuild_arrows", game_root)


func stop_guide() -> void:
	active = false
	time_remaining = 0.0
	if is_instance_valid(_arrows_root):
		_arrows_root.queue_free()
	_arrows_root = null


func get_poi_blink_alpha() -> float:
	if not active:
		return 1.0
	return 0.35 + absf(sin(_blink_phase)) * 0.65


func is_poi_highlighted() -> bool:
	return active


func _rebuild_arrows(game_root: Node3D) -> void:
	if not active or not is_instance_valid(_arrows_root):
		return
	for child in _arrows_root.get_children():
		child.queue_free()
	var znood := RuntimeGlobals.znood()
	if znood == null:
		return
	znood.ingest_markers_from_tree(game_root)
	for poi in znood.get_pois():
		var pos: Vector3 = poi.get("world_position", Vector3.ZERO)
		if pos == Vector3.ZERO:
			continue
		var arrow := PoiGuideArrow3DScript.new()
		arrow.name = "PoiArrow_%s" % str(poi.get("id", "poi"))
		_arrows_root.add_child(arrow)
		arrow.setup(pos, poi.get("color", Color(0.95, 0.82, 0.2)))


func _sync_arrows() -> void:
	if not is_instance_valid(_arrows_root):
		return
	var znood := RuntimeGlobals.znood()
	if znood == null:
		return
	var pois := znood.get_pois()
	var children := _arrows_root.get_children()
	if children.size() != pois.size():
		return
	for i in range(pois.size()):
		var arrow = children[i]
		if arrow.has_method("set_world_anchor"):
			arrow.set_world_anchor(pois[i].get("world_position", Vector3.ZERO))