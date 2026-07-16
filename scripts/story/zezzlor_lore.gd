class_name ZezzlorLore
extends RefCounted

const FACTION_NAME := "Zezzlor"
const FACTION_DESC := (
	"Kolonins ordnings- och lagmakt — blåklädda med batong. "
	+ "SRC och andra företag kan ha egna väktare; det är inte samma sak."
)

const RANKS := {
	"recruit": {
		"title": "Rekryt",
		"abbrev": "Rek",
		"color": Color(0.55, 0.72, 0.95),
	},
	"patrol": {
		"title": "Patrull",
		"abbrev": "Pat",
		"color": Color(0.42, 0.65, 0.92),
	},
	"officer": {
		"title": "Officer",
		"abbrev": "Off",
		"color": Color(0.32, 0.58, 0.88),
	},
	"sergeant": {
		"title": "Sergant",
		"abbrev": "Sgt",
		"color": Color(0.22, 0.48, 0.82),
	},
	"inspector": {
		"title": "Inspektör",
		"abbrev": "Ins",
		"color": Color(0.18, 0.38, 0.78),
	},
	"contract": {
		"title": "Kontrakt",
		"abbrev": "Ktr",
		"color": Color(0.38, 0.52, 0.9),
	},
}

const CHASE_RANK_ORDER: Array[String] = ["recruit", "patrol", "officer", "sergeant"]


static func get_rank(rank_id: String) -> Dictionary:
	return RANKS.get(rank_id, RANKS.patrol)


static func rank_title(rank_id: String) -> String:
	return str(get_rank(rank_id).get("title", "Patrull"))


static func rank_color(rank_id: String) -> Color:
	var rank: Dictionary = get_rank(rank_id)
	if rank.has("color"):
		return rank["color"] as Color
	return Color(0.45, 0.72, 1.0)


static func format_name(rank_id: String, personal_name: String = "") -> String:
	var title := rank_title(rank_id)
	var name := personal_name.strip_edges()
	if name != "":
		return "[%s] %s" % [title, name]
	return "[%s] %s" % [title, FACTION_NAME]


static func format_dialogue_title(rank_id: String, personal_name: String, subtitle: String = "") -> String:
	var base := format_name(rank_id, personal_name)
	if subtitle.strip_edges() != "":
		return "%s — %s" % [base, subtitle.strip_edges()]
	return base


static func chase_alert_body(rank_ids: Array) -> String:
	var labels: PackedStringArray = []
	for rank_id in rank_ids:
		labels.append(format_name(str(rank_id)))
	return (
		"%s svarar på slem mot civila.\n%s jagar dig med batong."
		% [FACTION_NAME, ", ".join(labels)]
	)


static func baton_strike_body(rank_id: String) -> String:
	return "%s — %s höjer batongen." % [FACTION_NAME, format_name(rank_id)]