class_name GleazerLore
extends RefCounted

const CLAN_NAME := "Gleazers"
const CLAN_MOTTO := "Vi försöker. Det räcker inte. Vi försöker igen."

const LABEL_COLOR := Color(0.35, 0.88, 0.42)

const ROLES := {
	"boss": {"title": "Överbefälhavare", "abbrev": "Öbf"},
	"gunner": {"title": "Vapenmästare", "abbrev": "Vap"},
	"scout": {"title": "Kartograf", "abbrev": "Krt"},
	"diplomat": {"title": "Diplomat", "abbrev": "Dip"},
	"tech": {"title": "Tekniker", "abbrev": "Tek"},
	"recruit": {"title": "Rekryt", "abbrev": "Rek"},
	"logistics": {"title": "Logistik", "abbrev": "Log"},
	"pr": {"title": "PR-chef", "abbrev": "PR"},
}


static func role_color(role_id: String) -> Color:
	match role_id:
		"boss":
			return Color(0.95, 0.72, 0.22)
		"gunner":
			return Color(0.28, 0.92, 0.38)
		"tech":
			return Color(0.42, 0.62, 0.95)
		_:
			return LABEL_COLOR


static func format_name(role_id: String, personal_name: String) -> String:
	var role: Dictionary = ROLES.get(role_id, ROLES.recruit)
	var nick := personal_name.strip_edges()
	if nick == "":
		return "%s %s" % [CLAN_NAME, role.title]
	return "%s — %s" % [nick, role.title]


static func format_dialogue_title(role_id: String, personal_name: String) -> String:
	return "%s — %s" % [CLAN_NAME, format_name(role_id, personal_name)]


static func pick_greeting(role_id: String, seed: int = -1) -> String:
	var pool: Array[String] = [
		"Hej! Gleazers behöver hjälp. Vi har en plan. Den är nästan klar. Typ.",
		"Kolonist! Perfekt timing — vi har precis saboterat vår egen quest. Ny behövs!",
		"Välkommen till Gleazers. Vi misslyckas professionellt sedan 20 minuter.",
		"Du ser kompetent ut. Det gör oss nervösa. Ta en quest ändå.",
	]
	if role_id == "boss":
		pool.append("Som Överbefälhavare beordrar jag: hjälp oss misslycka på ett större sätt.")
	if role_id == "gunner":
		pool.append("Min SlimeBlaster funkar halvt. Questen kommer gå likadant.")
	var pick := seed if seed >= 0 else randi()
	return pool[pick % pool.size()]


static func pick_failure(seed: int = -1) -> String:
	var pool: Array[String] = [
		"Quest fail. Vi glömde nämna att du skulle göra tvärtom.",
		"Nästan rätt! Tyvärr räknas nästan inte i Gleazers-manualen.",
		"Bra jobbat — för fel uppdrag. Vi startar om från början. Kanske.",
		"Du lyckades! ...nej vänta, det var fel checklista. Fail.",
		"Vi har granskat ditt arbete. Det var för bra. Misstänkt. Fail.",
		"SRC skulle varit imponerade. Vi är bara förvirrade. Quest fail.",
		"Patrullen kom. Vi skyllde på dig. Quest avslutad som misslyckad.",
	]
	var pick := seed if seed >= 0 else randi()
	return pool[pick % pool.size()]


static func pick_busy_line(seed: int = -1) -> String:
	var pool: Array[String] = [
		"Jag har redan gett dig en quest. Jag minns inte vilken. Gör den ändå.",
		"Återkom senare — jag letar efter nästa sätt att faila på.",
		"Vi håller på att skriva om målet. Det tar ungefär en evighet.",
	]
	var pick := seed if seed >= 0 else randi()
	return pool[pick % pool.size()]