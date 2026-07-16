extends Node

func arrange_panels(panels: Array[Control]) -> void:
	if panels.is_empty():
		return
		
	var primary_panel = _get_panel_by_role(panels, "player")
	var secondary_panel = null
	
	for p in panels:
		if p != primary_panel:
			secondary_panel = p
			break
			
	if primary_panel and secondary_panel:
		position_panel(primary_panel, "primary")
		position_panel(secondary_panel, "secondary")
	elif primary_panel:
		position_panel(primary_panel, "primary_centered")
	else:
		for p in panels:
			position_panel(p, "centered")

func position_panel(panel: Control, layout_mode: String) -> void:
	panel.set_anchors_preset(Control.PRESET_FULL_RECT, false)
	panel.offset_left = 0
	panel.offset_top = 0
	panel.offset_right = 0
	panel.offset_bottom = 0
	
	match layout_mode:
		"primary":
			panel.anchor_left = 0.55
			panel.anchor_right = 0.98
			panel.offset_left = 16
			panel.offset_right = -16
			panel.anchor_top = 0.1
			panel.anchor_bottom = 0.9
		"primary_centered":
			panel.anchor_left = 0.25
			panel.anchor_right = 0.75
			panel.anchor_top = 0.1
			panel.anchor_bottom = 0.9
		"secondary":
			panel.anchor_left = 0.02
			panel.anchor_right = 0.45
			panel.offset_left = 16
			panel.offset_right = -8
			panel.anchor_top = 0.1
			panel.anchor_bottom = 0.9
		"centered":
			panel.anchor_left = 0.15
			panel.anchor_right = 0.85
			panel.anchor_top = 0.1
			panel.anchor_bottom = 0.9

func _get_panel_by_role(panels: Array[Control], role: String) -> Control:
	for p in panels:
		if p.has_meta("ui_role") and p.get_meta("ui_role") == role:
			return p
	return null
