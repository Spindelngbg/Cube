class_name ShopDoorBuilder
extends RefCounted

## Gemensam butiksentré: karm, dubbeldörrar (glas), handtag, tröskel.
## Byggnadens framsida antas peka +Z.

const FRAME_DEFAULT := Color(0.22, 0.24, 0.28)
const DOOR_DEFAULT := Color(0.32, 0.28, 0.24)
const GLASS_DEFAULT := Color(0.55, 0.72, 0.88, 0.42)
const HANDLE := Color(0.85, 0.78, 0.35)


## face_z = framsidans Z i butikslokal space. half_w = halv byggnadsbredd.
static func add_entrance(
	parent: Node3D,
	face_z: float,
	half_w: float,
	door_w: float = 1.9,
	door_h: float = 2.45,
	wall_h: float = 3.6,
	frame_color: Color = FRAME_DEFAULT,
	door_color: Color = DOOR_DEFAULT,
	accent: Color = Color(0.7, 0.55, 0.3),
	ajar_deg: float = 22.0
) -> Node3D:
	var root := Node3D.new()
	root.name = "ShopEntrance"
	parent.add_child(root)

	var frame_t := 0.14
	var door_half := door_w * 0.5
	var open_side := (half_w - door_half) * 0.5 + door_half * 0.5
	# Sidopaneler på framsidan (om det finns utrymme utanför dörröppningen).
	var side_panel_w := maxf(half_w - door_half - 0.08, 0.35)
	if side_panel_w > 0.4:
		var sides: Array[float] = [-1.0, 1.0]
		for side in sides:
			var panel := _box(
				Vector3(side_panel_w, wall_h, frame_t),
				frame_color.lightened(0.05)
			)
			var x: float = side * (door_half + side_panel_w * 0.5 + 0.04)
			panel.position = Vector3(x, wall_h * 0.5, face_z)
			root.add_child(panel)

	# Karm: vänster, höger, överliggare
	var left_jamb := _box(Vector3(frame_t, door_h + 0.12, frame_t * 1.4), frame_color)
	left_jamb.position = Vector3(-door_half - frame_t * 0.5, door_h * 0.5 + 0.02, face_z)
	root.add_child(left_jamb)

	var right_jamb := _box(Vector3(frame_t, door_h + 0.12, frame_t * 1.4), frame_color)
	right_jamb.position = Vector3(door_half + frame_t * 0.5, door_h * 0.5 + 0.02, face_z)
	root.add_child(right_jamb)

	var lintel := _box(Vector3(door_w + frame_t * 2.2, frame_t * 1.3, frame_t * 1.4), frame_color)
	lintel.position = Vector3(0.0, door_h + frame_t * 0.85, face_z)
	root.add_child(lintel)

	# Tröskel
	var sill := _box(Vector3(door_w + 0.2, 0.08, 0.35), frame_color.darkened(0.1))
	sill.position = Vector3(0.0, 0.04, face_z + 0.08)
	root.add_child(sill)

	# Dubbeldörrar — något öppna
	var ajar := deg_to_rad(ajar_deg)
	_add_door_leaf(
		root,
		Vector3(-door_half * 0.5 - 0.02, door_h * 0.5, face_z + 0.02),
		Vector3(door_half - 0.06, door_h - 0.08, 0.08),
		door_color,
		accent,
		-ajar,
		true
	)
	_add_door_leaf(
		root,
		Vector3(door_half * 0.5 + 0.02, door_h * 0.5, face_z + 0.02),
		Vector3(door_half - 0.06, door_h - 0.08, 0.08),
		door_color,
		accent,
		ajar,
		false
	)

	# Skylt ovanför
	var open_sign := Label3D.new()
	open_sign.text = "ÖPPET"
	open_sign.font_size = 22
	open_sign.modulate = accent.lightened(0.15)
	open_sign.outline_modulate = Color(0.05, 0.05, 0.08, 0.9)
	open_sign.outline_size = 4
	open_sign.position = Vector3(0.0, door_h + 0.55, face_z + 0.12)
	open_sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	root.add_child(open_sign)

	return root


static func _add_door_leaf(
	parent: Node3D,
	pos: Vector3,
	size: Vector3,
	door_color: Color,
	accent: Color,
	yaw: float,
	is_left: bool
) -> void:
	var pivot := Node3D.new()
	pivot.name = "DoorLeaf_%s" % ("L" if is_left else "R")
	# Pivot vid hinge-sidan
	var hinge_x := pos.x + (-size.x * 0.5 if is_left else size.x * 0.5)
	pivot.position = Vector3(hinge_x, 0.0, pos.z)
	pivot.rotation.y = yaw
	parent.add_child(pivot)

	var leaf := _box(size, door_color)
	leaf.position = Vector3((size.x * 0.5 if is_left else -size.x * 0.5), pos.y, 0.0)
	var mat := leaf.material_override as StandardMaterial3D
	if mat:
		mat.metallic = 0.18
		mat.roughness = 0.55
	pivot.add_child(leaf)

	# Glasruta
	var glass_w := size.x * 0.55
	var glass_h := size.y * 0.42
	var glass := _box(Vector3(glass_w, glass_h, 0.04), GLASS_DEFAULT)
	glass.position = Vector3(
		(size.x * 0.5 if is_left else -size.x * 0.5),
		pos.y + size.y * 0.12,
		0.05
	)
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = GLASS_DEFAULT
	gmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gmat.roughness = 0.08
	gmat.metallic = 0.2
	gmat.emission_enabled = true
	gmat.emission = accent
	gmat.emission_energy_multiplier = 0.12
	glass.material_override = gmat
	pivot.add_child(glass)

	# Handtag
	var handle := _box(Vector3(0.05, 0.28, 0.08), HANDLE)
	handle.position = Vector3(
		(size.x * 0.82 if is_left else -size.x * 0.82),
		pos.y,
		0.08
	)
	var hmat := StandardMaterial3D.new()
	hmat.albedo_color = HANDLE
	hmat.metallic = 0.85
	hmat.roughness = 0.25
	handle.material_override = hmat
	pivot.add_child(handle)


static func _box(size: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.65
	mi.material_override = mat
	return mi
