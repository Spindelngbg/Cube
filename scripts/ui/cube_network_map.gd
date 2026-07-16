class_name CubeNetworkMap
extends PanelContainer

const NODE_LAYOUT := {
	"hub": Vector2(120, 78),
	"satellite_left": Vector2(28, 78),
	"satellite_top_a": Vector2(120, 22),
	"satellite_top_b": Vector2(212, 22),
	"satellite_right": Vector2(212, 78),
}

const HUB_LINKS := [
	"satellite_left",
	"satellite_top_a",
	"satellite_top_b",
	"satellite_right",
]

const ACTIVE_COLOR := Color(0.35, 0.92, 0.42)
const IDLE_COLOR := Color(0.72, 0.74, 0.78)
const HUB_COLOR := Color(0.92, 0.86, 0.72)
const NODE_RADIUS := 10.0

var _spawn_id := ""
var _map_open := false
var _canvas: Control


func _ready() -> void:
	SpiderTheme.apply_to(self)
	visible = false
	custom_minimum_size = Vector2(260, 210)

	_canvas = Control.new()
	_canvas.name = "NetworkCanvas"
	_canvas.custom_minimum_size = Vector2(240, 170)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_on_draw)
	add_child(_canvas)


func toggle() -> void:
	_map_open = not _map_open
	visible = _map_open
	if _map_open:
		_canvas.queue_redraw()


func set_active_spawn(spawn_id: String) -> void:
	_spawn_id = SpawnPoints.normalize_id(spawn_id)
	if visible:
		_canvas.queue_redraw()


func _on_draw() -> void:
	var rect := _canvas.get_rect()
	_canvas.draw_rect(rect, Color(0.04, 0.05, 0.07, 0.94), true)
	_canvas.draw_rect(rect, Color(SpiderTheme.BLOOD.r, SpiderTheme.BLOOD.g, SpiderTheme.BLOOD.b, 0.45), false, 2.0)
	_canvas.draw_string(
		ThemeDB.fallback_font,
		Vector2(8, 18),
		"Kubnätverk",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		13,
		Color(SpiderTheme.BONE.r, SpiderTheme.BONE.g, SpiderTheme.BONE.b, 0.9)
	)

	var hub_pos := NODE_LAYOUT["hub"]
	for target_id in HUB_LINKS:
		_canvas.draw_line(hub_pos, NODE_LAYOUT[target_id], Color(0.45, 0.5, 0.58, 0.75), 3.0)

	for node_id in NODE_LAYOUT.keys():
		var pos: Vector2 = NODE_LAYOUT[node_id]
		var color := HUB_COLOR
		if node_id != "hub" and node_id == _spawn_id:
			color = ACTIVE_COLOR
		elif node_id != "hub":
			color = IDLE_COLOR
		_canvas.draw_circle(pos, NODE_RADIUS + 1.5, Color(0, 0, 0, 0.35))
		_canvas.draw_circle(pos, NODE_RADIUS, color)

		var label := _label_for(node_id)
		_canvas.draw_string(
			ThemeDB.fallback_font,
			pos + Vector2(-36, 24),
			label,
			HORIZONTAL_ALIGNMENT_LEFT,
			72,
			9,
			Color(1, 1, 1, 0.55)
		)


func _label_for(node_id: String) -> String:
	match node_id:
		"hub":
			return "Huvudkub"
		_:
			return SpawnPoints.get_spawn_name(node_id).replace("kuben", "kub")