class_name RecipeIngredient
extends Resource

@export var item: ItemDefinition = null
@export var count: int = 1

func is_valid() -> bool:
	return item != null and count > 0
