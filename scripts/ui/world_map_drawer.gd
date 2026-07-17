class_name WorldMapDrawer
extends RefCounted

const GuiFontLibraryScript = preload("res://scripts/ui/gui_font_library.gd")
const MAP_PADDING := 10.0


static func inner_rect(canvas_rect: Rect2) -> Rect2:
	return Rect2(
		MAP_PADDING,
		MAP_PADDING,
		canvas_rect.size.x - MAP_PADDING * 2.0,
		canvas_rect.size.y - MAP_PADDING * 2.0
	)


static func map_click_to_world(
	local_pos: Vector2,
	canvas_rect: Rect2,
	spawn_id: String,
	players: Dictionary,
	local_peer_id: int
) -> Vector3:
	var inner := inner_rect(canvas_rect)
	if not inner.has_point(local_pos):
		return Vector3.ZERO
	var nx := (local_pos.x - inner.position.x) / inner.size.x
	var nz := (local_pos.y - inner.position.y) / inner.size.y
	var center := get_map_center(players, local_peer_id, spawn_id)
	var half := SpawnPoints.get_map_view_half_extent(spawn_id)
	var rel_x := (nx - 0.5) * half * 2.0
	var rel_z := (nz - 0.5) * half * 2.0
	return Vector3(center.x + rel_x, 0.0, center.z + rel_z)


static func get_map_center(players: Dictionary, local_peer_id: int, spawn_id: String) -> Vector3:
	if players.has(local_peer_id):
		var player: Node3D = players[local_peer_id]
		if player != null and is_instance_valid(player):
			return player.global_position
	return SpawnPoints.get_map_view_center(spawn_id)


static func draw(
	canvas: Control,
	inner: Rect2,
	spawn_id: String,
	players: Dictionary,
	local_peer_id: int,
	monsters: Array,
	pois: Array = [],
	waypoint: Vector3 = Vector3.ZERO,
	has_waypoint: bool = false,
	backup_pings: Array = [],
	blink_alpha: float = 1.0,
	show_footer: bool = false,
	show_text: bool = true,
	poi_blink_alpha: float = 1.0,
	highlight_pois: bool = false
) -> void:
	if inner.size.x <= 4.0 or inner.size.y <= 4.0:
		return

	var map_center := get_map_center(players, local_peer_id, spawn_id)
	var half_extent := maxf(SpawnPoints.get_map_view_half_extent(spawn_id), 1.0)
	var player_px := Vector2(
		inner.position.x + inner.size.x * 0.5,
		inner.position.y + inner.size.y * 0.5
	)

	canvas.draw_rect(inner, Color(0.05, 0.06, 0.08, 0.92), true)
	canvas.draw_rect(inner, SpiderTheme.UI_BORDER, false, 1.0)

	var grid_step := inner.size.x / 6.0
	for i in range(1, 6):
		var x := inner.position.x + grid_step * i
		var y := inner.position.y + grid_step * i
		canvas.draw_line(Vector2(x, inner.position.y), Vector2(x, inner.end.y), Color(1, 1, 1, 0.05), 1.0)
		canvas.draw_line(Vector2(inner.position.x, y), Vector2(inner.end.x, y), Color(1, 1, 1, 0.05), 1.0)

	canvas.draw_circle(player_px, 3.0, Color(1, 1, 1, 0.12))

	var elevator_pos := _elevator_map_position(spawn_id)
	if _is_in_map_view(elevator_pos, map_center, half_extent):
		var elev_px := _world_to_map(elevator_pos, inner, map_center, half_extent, true)
		canvas.draw_rect(Rect2(elev_px - Vector2(5, 5), Vector2(10, 10)), Color(0.95, 0.75, 0.2, 0.9), true)

	if show_text:
		GuiFontLibraryScript.draw(
			canvas,
			inner.position + Vector2(4, 16),
			"N",
			GuiFontLibraryScript.FONT_SMALL,
			Color(1, 1, 1, 0.35)
		)

	for poi in pois:
		var poi_pos: Vector3 = poi.get("world_position", Vector3.ZERO)
		var px := _world_to_map(poi_pos, inner, map_center, half_extent, true)
		var color: Color = poi.get("color", Color(0.45, 0.92, 0.68))
		var alpha := poi_blink_alpha if highlight_pois else 1.0
		if highlight_pois:
			var pulse := 10.0 + poi_blink_alpha * 6.0
			canvas.draw_circle(px, pulse, Color(color.r, color.g, color.b, alpha * 0.22))
			canvas.draw_circle(px, 7.0 + poi_blink_alpha * 2.0, Color(color.r, color.g, color.b, alpha * 0.35))
		canvas.draw_rect(
			Rect2(px - Vector2(5, 5), Vector2(10, 10)),
			Color(color.r, color.g, color.b, alpha),
			true
		)
		if show_text:
			var label_pos := Vector2(
				clampf(px.x + 6.0, inner.position.x + 2.0, inner.end.x - 72.0),
				clampf(px.y - 4.0, inner.position.y + 12.0, inner.end.y - 4.0)
			)
			GuiFontLibraryScript.draw(
				canvas,
				label_pos,
				str(poi.get("name", "")),
				GuiFontLibraryScript.FONT_MAP,
				Color(color.r, color.g, color.b, 0.9)
			)

	if has_waypoint:
		var wpx := _world_to_map(waypoint, inner, map_center, half_extent, true)
		canvas.draw_circle(wpx, 6.0, Color(0.35, 0.75, 1.0, 0.35))
		canvas.draw_circle(wpx, 4.0, Color(0.55, 0.9, 1.0, 0.95))
		canvas.draw_line(wpx - Vector2(0, 10), wpx + Vector2(0, 2), Color(0.55, 0.9, 1.0, 0.9), 2.0)

	for ping in backup_pings:
		var ping_pos: Vector3 = ping.get("position", Vector3.ZERO)
		var ping_px := _world_to_map(ping_pos, inner, map_center, half_extent, true)
		var kind := str(ping.get("kind", "backup"))
		var alpha := blink_alpha if kind == "backup" else 0.65 + blink_alpha * 0.35
		var ping_color := Color(0.95, 0.12, 0.1, alpha) if kind == "backup" else Color(0.95, 0.55, 0.1, alpha)
		canvas.draw_circle(ping_px, 7.0 + blink_alpha * 3.0, Color(ping_color.r, ping_color.g, ping_color.b, alpha * 0.35))
		canvas.draw_circle(ping_px, 5.0, ping_color)

	for monster in monsters:
		if monster == null or not is_instance_valid(monster):
			continue
		var mpx := _world_to_map(monster.global_position, inner, map_center, half_extent, true)
		canvas.draw_circle(mpx, 2.5, Color(0.95, 0.35, 0.2, 0.85))

	for peer_id in players.keys():
		var player: Node3D = players[peer_id]
		if player == null or not is_instance_valid(player):
			continue
		var is_local := int(peer_id) == local_peer_id
		var px := player_px if is_local else _world_to_map(player.global_position, inner, map_center, half_extent, true)
		var yaw := _player_map_yaw(player)
		# Röd bloddroppe: spetsen pekar åt den riktning man går / tittar.
		var color := Color(0.82, 0.08, 0.12, 0.98) if is_local else Color(0.95, 0.35, 0.28, 0.9)
		var size := 7.5 if is_local else 5.5
		_draw_blood_drop(canvas, px, yaw, size, color)

	if show_text and show_footer:
		var title := SpawnPoints.get_spawn_name(spawn_id)
		if title == "":
			title = "Karta"
		GuiFontLibraryScript.draw(
			canvas,
			inner.position + Vector2(4, inner.size.y - 4),
			title,
			GuiFontLibraryScript.FONT_SMALL,
			Color(SpiderTheme.BONE.r, SpiderTheme.BONE.g, SpiderTheme.BONE.b, 0.7)
		)


static func _player_map_yaw(player: Node3D) -> float:
	# Föredra rörelseriktning när man går, annars titt-riktning.
	if player is CharacterBody3D:
		var body := player as CharacterBody3D
		var flat := Vector2(body.velocity.x, body.velocity.z)
		if flat.length_squared() > 0.12:
			return atan2(flat.x, flat.y)
	if player.has_method("get_facing_yaw"):
		return float(player.get_facing_yaw())
	return player.rotation.y


## Bloddroppe på kartan. Spetsen (vassa delen) pekar i facing-riktning.
## yaw = atan2(dir.x, dir.z) i world space.
static func _draw_blood_drop(
	canvas: Control,
	center: Vector2,
	yaw: float,
	size: float,
	color: Color
) -> void:
	# Världsforward från yaw → karta (x höger, y ner = world z).
	var dir_map := Vector2(sin(yaw), cos(yaw))
	if dir_map.length_squared() < 0.0001:
		dir_map = Vector2(0.0, -1.0)
	dir_map = dir_map.normalized()
	# Droppe i lokal rymd: spets vid +Y (ner), rundad kropp vid -Y (upp).
	# Rotera så lokal +Y blir dir_map.
	var angle := dir_map.angle() - PI * 0.5
	var cos_a := cos(angle)
	var sin_a := sin(angle)

	var local_pts: Array[Vector2] = [
		Vector2(0.0, size), # spets (riktning)
		Vector2(size * 0.42, size * 0.45),
		Vector2(size * 0.55, size * 0.05),
		Vector2(size * 0.48, -size * 0.35),
		Vector2(size * 0.22, -size * 0.62),
		Vector2(0.0, -size * 0.72), # topp
		Vector2(-size * 0.22, -size * 0.62),
		Vector2(-size * 0.48, -size * 0.35),
		Vector2(-size * 0.55, size * 0.05),
		Vector2(-size * 0.42, size * 0.45),
	]
	var pts := PackedVector2Array()
	var outline := PackedVector2Array()
	for p in local_pts:
		var rx := p.x * cos_a - p.y * sin_a
		var ry := p.x * sin_a + p.y * cos_a
		var world := center + Vector2(rx, ry)
		pts.append(world)
		# Lätt större outline
		var o := p * 1.18
		var ox := o.x * cos_a - o.y * sin_a
		var oy := o.x * sin_a + o.y * cos_a
		outline.append(center + Vector2(ox, oy))

	canvas.draw_colored_polygon(outline, Color(0.05, 0.02, 0.02, 0.55))
	canvas.draw_colored_polygon(pts, color)
	# Highlight (glans) i den runda delen
	var hl_local := Vector2(-size * 0.12, -size * 0.28)
	var hl := center + Vector2(
		hl_local.x * cos_a - hl_local.y * sin_a,
		hl_local.x * sin_a + hl_local.y * cos_a
	)
	canvas.draw_circle(hl, size * 0.16, Color(1.0, 0.45, 0.48, 0.45))


static func _elevator_map_position(spawn_id: String) -> Vector3:
	var entry := SpawnPoints.get_entry(spawn_id)
	var mount := str(entry.get("elevator_mount", "left"))
	var world_size := SpawnPoints.get_extent_m()
	var half := world_size * 0.5
	match mount:
		"left":
			return Vector3(80.0, 0, half)
		"right":
			return Vector3(world_size - 80.0, 0, half)
		"top":
			var index := int(entry.get("elevator_index", 0))
			var lane_x := world_size * (0.333 if index == 0 else 0.667)
			return Vector3(lane_x, 0, 80.0)
		_:
			return SpawnPoints.get_position(spawn_id)


static func _is_in_map_view(world_pos: Vector3, center: Vector3, half: float) -> bool:
	return (
		absf(world_pos.x - center.x) <= half
		and absf(world_pos.z - center.z) <= half
	)


static func _world_to_map(
	world_pos: Vector3,
	inner: Rect2,
	center: Vector3,
	half: float,
	clamp_to_edge: bool
) -> Vector2:
	var rel_x := world_pos.x - center.x
	var rel_z := world_pos.z - center.z
	var nx := 0.5 + rel_x / (half * 2.0)
	var nz := 0.5 + rel_z / (half * 2.0)
	if clamp_to_edge:
		nx = clampf(nx, 0.03, 0.97)
		nz = clampf(nz, 0.03, 0.97)
	return Vector2(
		inner.position.x + nx * inner.size.x,
		inner.position.y + nz * inner.size.y
	)