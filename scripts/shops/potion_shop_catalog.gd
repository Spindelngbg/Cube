class_name PotionShopCatalog
extends RefCounted

const OWNER_NAME := "Mystika-Mira"

const GREETING := (
	"Välkommen till Brygdhörnan! Jag är Mystika-Mira. "
	+ "Här säljs magiska brygder — mer skada, mer livskraft, mer galenskap."
)

const SHOP_POTIONS: Array[String] = [
	"stridsbrygd",
	"livskraftsbrygd",
	"berserkerbrygd",
	"jattelivsbrygd",
	"krigarens_elixir",
]

const REACTIONS := {
	"stridsbrygd": (
		"Stridsbrygden! Alla dina vapen hugger och skjuter hårdare en stund. "
		+ "Perfekt före en jobbig promenad bland hybridzombies."
	),
	"livskraftsbrygd": (
		"Livskraftsbrygden! Varm i magen, tjockare i huden. "
		+ "Din maxhälsa stiger — drick när du känner dig skör."
	),
	"berserkerbrygd": (
		"Berserkerbrygden! Kortare, men brutal. "
		+ "När du behöver att varje skott räknas — och du inte har tid att tveka."
	),
	"jattelivsbrygd": (
		"Jättelivsbrygden! Nästan dubbelt så mycket livskraft som den lilla flaskan. "
		+ "Smakar som rost och hopp."
	),
	"krigarens_elixir": (
		"Krigarens Elixir! Min stolthet. Mer skada på alla vapen och mer hälsa samtidigt. "
		+ "Dyrt? Ja. Värt det när kolonin skriker? Absolut."
	),
}


static func get_greeting() -> String:
	return GREETING


static func get_potion_reaction(potion_id: String) -> String:
	return str(REACTIONS.get(potion_id, "En bra brygd. Drick med respekt."))


static func get_potion_summary(potion_id: String) -> String:
	var price := ItemCatalog.get_shop_price(potion_id)
	var duration := int(ItemCatalog.get_buff_duration(potion_id))
	var parts: PackedStringArray = []
	var dmg_mult := ItemCatalog.get_damage_multiplier(potion_id)
	if dmg_mult > 1.0:
		parts.append("+%d%% vapenskada" % int(round((dmg_mult - 1.0) * 100.0)))
	var max_hp := int(ItemCatalog.get_potion_max_hp_bonus(potion_id))
	if max_hp > 0:
		parts.append("+%d max-HP" % max_hp)
	var effect := ", ".join(parts) if not parts.is_empty() else "okänd effekt"
	return "%s — %s | %ds | %d %s" % [
		ItemCatalog.get_display_name(potion_id),
		effect,
		duration,
		price,
		ItemCatalog.currency_symbol(),
	]


static func get_potion_button_label(potion_id: String) -> String:
	var price := ItemCatalog.get_shop_price(potion_id)
	var rarity := ItemCatalog.get_rarity(potion_id)
	return "[%s] %s — %d %s" % [
		rarity.to_upper(),
		ItemCatalog.get_display_name(potion_id),
		price,
		ItemCatalog.currency_symbol(),
	]


static func apply_potion_effects(potion_id: String) -> void:
	var duration := ItemCatalog.get_buff_duration(potion_id)
	if duration <= 0.0:
		duration = 60.0
	var dmg_mult := ItemCatalog.get_damage_multiplier(potion_id)
	if dmg_mult > 1.0:
		BuffManager.apply_damage_buff(dmg_mult, duration)
	var max_hp := ItemCatalog.get_potion_max_hp_bonus(potion_id)
	if max_hp > 0.0:
		BuffManager.apply_max_hp_buff(max_hp, duration)
