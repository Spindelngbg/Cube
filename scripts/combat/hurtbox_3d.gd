extends Area3D

## Synlig träffyta för projektiler — vidarebefordrar skada till föräldern.


func _ready() -> void:
	collision_layer = 4
	collision_mask = 0
	monitorable = true
	monitoring = false