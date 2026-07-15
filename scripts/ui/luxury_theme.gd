class_name LuxuryTheme
extends RefCounted

## Bakåtkompatibelt alias – använd SpiderTheme.
static func apply_to(root: Control) -> void:
	SpiderTheme.apply_to(root)


static func style_title(label: Label, size: int = 52) -> void:
	SpiderTheme.style_title(label, size)


static func style_subtitle(label: Label) -> void:
	SpiderTheme.style_subtitle(label)


static func style_status(label: Label) -> void:
	SpiderTheme.style_status(label)


static func style_tab_button(button: Button, active: bool) -> void:
	SpiderTheme.style_tab_button(button, active)