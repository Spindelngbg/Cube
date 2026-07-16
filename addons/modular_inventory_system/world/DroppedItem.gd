@tool
extends RigidBody3D
class_name DroppedItem

@export var item_: ItemDefinition
@export var count: int = 1
@export var durability: int = -1

func _ready() -> void:
	if Engine.is_editor_hint(): return
	_setup_model()
	#_setup_pickup()

func _setup_model() -> void:
	if item_ and item_.model_scene:
		var model_instance = item_.model_scene.instantiate()
		add_child(model_instance)
	else:
		var mesh = MeshInstance3D.new()
		var box_mesh = BoxMesh.new()
		box_mesh.size = Vector3(0.7, 0.7, 0.7)
		mesh.mesh = box_mesh
		add_child(mesh)

func _setup_pickup() -> void:
	var pickup = null # PickupComponent.new() 
	pickup.name = "PickupComponent"
	add_child(pickup)
	
	pickup.item_data = item_
	pickup.count = count
	pickup.destroy_on_pickup = true
	
	var display_name = item_.display_name if item_ else "Item"
	pickup.interaction_text = "Pick Up %s" % display_name
	
	if durability >= 0:
		set_meta("durability", durability)
