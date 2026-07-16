class_name ZnoodPoiMarker
extends Node3D

@export var poi_id := ""
@export var display_name := "Plats"
@export var category := "shop"
@export var keywords: PackedStringArray = PackedStringArray()
@export var map_color := Color(0.45, 0.92, 0.68)


func _ready() -> void:
	add_to_group("znood_poi")