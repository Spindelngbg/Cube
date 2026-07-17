class_name ItemIconFactory
extends RefCounted

const ICON_SIZE := 48


static func create_icon(def) -> Texture2D:
	var item_id := str(def.id)
	var icon_key := ItemCatalog.get_icon_key(item_id)
	if icon_key == "food":
		return _create_food_icon(def)
	if icon_key == "boots" or ItemCatalog.is_footwear(item_id):
		return _create_boots_icon(def)
	var rarity := str(def.custom_metadata.get("rarity", "common"))
	var hp_bonus := float(def.custom_metadata.get("hp_bonus", 0))
	var image := Image.create(ICON_SIZE, ICON_SIZE, false, Image.FORMAT_RGBA8)
	var base := ItemCatalog.rarity_color(rarity)
	image.fill(base.darkened(0.22))
	_draw_border(image, base.lightened(0.2))
	if hp_bonus > 0.0:
		_draw_plus(image, Color(0.93, 0.97, 0.9))
	return ImageTexture.create_from_image(image)


static func slot_label(display_name: String) -> String:
	var cleaned := display_name.strip_edges()
	if cleaned.is_empty():
		return "?"
	var parts := cleaned.split("-", false)
	if parts.size() >= 2:
		return parts[0]
	if cleaned.length() <= 12:
		return cleaned
	return cleaned.substr(0, 12)


static func _create_boots_icon(def) -> Texture2D:
	var rarity := str(def.custom_metadata.get("rarity", "common"))
	var image := Image.create(ICON_SIZE, ICON_SIZE, false, Image.FORMAT_RGBA8)
	var base := ItemCatalog.rarity_color(rarity)
	image.fill(Color(0.08, 0.1, 0.09, 1.0))
	_draw_border(image, base.lightened(0.15))
	var leather := Color(0.18, 0.55, 0.42)
	var sole := Color(0.12, 0.12, 0.14)
	# Left boot
	for y in range(18, 36):
		for x in range(10, 20):
			image.set_pixel(x, y, leather if y < 32 else sole)
	# Right boot
	for y in range(18, 36):
		for x in range(28, 38):
			image.set_pixel(x, y, leather if y < 32 else sole)
	# Laces / highlight
	var lace := base.lightened(0.25)
	for x in range(12, 18):
		image.set_pixel(x, 22, lace)
		image.set_pixel(x, 25, lace)
	for x in range(30, 36):
		image.set_pixel(x, 22, lace)
		image.set_pixel(x, 25, lace)
	return ImageTexture.create_from_image(image)


static func _create_food_icon(def) -> Texture2D:
	var rarity := str(def.custom_metadata.get("rarity", "common"))
	var image := Image.create(ICON_SIZE, ICON_SIZE, false, Image.FORMAT_RGBA8)
	var base := ItemCatalog.rarity_color(rarity)
	image.fill(Color(0.1, 0.09, 0.08, 1.0))
	_draw_border(image, base.lightened(0.15))
	_draw_food_ration(image, base)
	return ImageTexture.create_from_image(image)


static func _draw_food_ration(image: Image, accent: Color) -> void:
	var tin := Color(0.72, 0.74, 0.78)
	var tin_dark := Color(0.42, 0.44, 0.48)
	var label_col := accent.lightened(0.08)
	var food := Color(0.86, 0.62, 0.28)
	var food_dark := Color(0.62, 0.42, 0.18)

	# Ransonburk
	for y in range(14, 36):
		for x in range(14, 34):
			var edge := x <= 15 or x >= 32 or y <= 15 or y >= 34
			image.set_pixel(x, y, tin_dark if edge else tin)

	# Lock / öppning
	for x in range(18, 30):
		image.set_pixel(x, 14, Color(0.9, 0.9, 0.92))
		image.set_pixel(x, 15, tin_dark)

	# Etikett
	for y in range(20, 28):
		for x in range(17, 31):
			image.set_pixel(x, y, label_col)

	# Bröd/bit på etiketten
	for y in range(22, 26):
		for x in range(21, 27):
			image.set_pixel(x, y, food)
	for offset in [-1, 0, 1]:
		image.set_pixel(23 + offset, 21, food_dark)
		image.set_pixel(24 + offset, 26, food_dark)

	# Ånga / matdoft
	var steam := Color(0.95, 0.95, 0.98, 0.85)
	image.set_pixel(20, 12, steam)
	image.set_pixel(22, 11, steam)
	image.set_pixel(24, 10, steam)
	image.set_pixel(26, 11, steam)
	image.set_pixel(28, 12, steam)

	# Liten gaffel-silhuett
	var fork := Color(0.88, 0.9, 0.94)
	for y in range(24, 31):
		image.set_pixel(18, y, fork)
	for prong in [17, 19]:
		for y in range(24, 27):
			image.set_pixel(prong, y, fork)


static func _draw_border(image: Image, color: Color) -> void:
	var last := ICON_SIZE - 1
	for x in ICON_SIZE:
		image.set_pixel(x, 0, color)
		image.set_pixel(x, last, color)
	for y in ICON_SIZE:
		image.set_pixel(0, y, color)
		image.set_pixel(last, y, color)


static func _draw_plus(image: Image, color: Color) -> void:
	var center := ICON_SIZE / 2
	for offset in range(-5, 6):
		image.set_pixel(center + offset, center, color)
		image.set_pixel(center, center + offset, color)