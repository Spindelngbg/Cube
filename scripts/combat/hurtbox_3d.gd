class_name Hurtbox3D
extends Area3D

## Synlig träffyta för projektiler — vidarebefordrar skada till föräldern.


func _ready() -> void:
	collision_layer = 8
	collision_mask = 0
	monitorable = true
	monitoring = false


static func attach(
	parent: Node3D,
	radius: float = 0.62,
	height: float = 2.1,
	center_y: float = 0.95
) -> Hurtbox3D:
	var hurtbox := Hurtbox3D.new()
	hurtbox.name = "Hurtbox"
	var shape_node := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = radius
	capsule.height = height
	shape_node.shape = capsule
	shape_node.position = Vector3(0.0, center_y, 0.0)
	hurtbox.add_child(shape_node)
	parent.add_child(hurtbox)
	return hurtbox