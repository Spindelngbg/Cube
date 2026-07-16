class_name CubePauseMenu
extends PauseMenuUI


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.anchor_right = 1
	dim.anchor_bottom = 1
	add_child(dim)

	var center := CenterContainer.new()
	center.anchor_right = 1
	center.anchor_bottom = 1
	add_child(center)

	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", theme_data.panel_stylebox())
	_panel.custom_minimum_size = Vector2(theme_data.menu_max_width, 0)
	center.add_child(_panel)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	_panel.add_child(col)

	var title := Label.new()
	title.text = "Paus"
	title.add_theme_font_size_override("font_size", theme_data.heading_font_size)
	title.add_theme_color_override("font_color", theme_data.text)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)

	_first_button = _add_button(col, "Fortsätt", resume)
	_add_button(col, "Inställningar", _open_options)
	_add_button(col, "Huvudmeny", _main_menu)
	_add_button(col, "Avsluta spelet", _quit)