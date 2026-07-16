class_name WeaponShopCatalog
extends RefCounted

const OWNER_NAME := "Stål-Sven"

const GREETING := (
	"Välkommen till kolonins finaste vapenburk! "
	+ "Jag är Stål-Sven. Välj ett vapen i listan så säger jag vad jag tycker."
)

const REACTIONS := {
	"slimeshooter": (
		"Ahh, klassikern! Slimeshooter — frätande, grönt och kolonist-godkänt. "
		+ "Perfekt när du vill lösa problem utan att städa efter dig."
	),
	"mountblast_3000": (
		"Ahh! Bra val! En Mountblast 3000! "
		+ "Perfekt när det inte finns någon annan utväg!"
	),
	"neon_stinger_mk2": (
		"Neon Stinger Mk-II! Snabb som skvaller i Neo-Washington. "
		+ "Pirr i fingrarna och lila gnistor — min personliga favorit på fredagar."
	),
	"corrosion_cannon_x9": (
		"Corrosion Cannon X9! Det här är inte en pistol, det är en protest. "
		+ "Slem så aggressivt att till och med Zezzlor blinkar två gånger."
	),
	"plasma_ripper_7": (
		"Plasma Ripper 7! Lagom brutal, lagom elegant. "
		+ "Som att skära genom byråkrati med en glödande linjal."
	),
	"voltthrower_ultra": (
		"Voltthrower Ultra! Brum brum, zapp zapp — kolonins egna åskväder i handformat. "
		+ "Jag rekommenderar öronproppar. Till dig, inte offret."
	),
	"shadow_fang": (
		"Shadow Fang! Diskret, snabb, lite för dramatisk namnskylt — precis som jag gillar det."
	),
	"chitin_cleaver": (
		"Chitin Cleaver! Kitin från spindelkolonin, slipad av någon med tydliga känslomässiga problem. "
		+ "Bra kött."
	),
	"hsg_survival_axe": (
		"Överlevnadsyxan! Importerad från en annan dimension där allt är voxel och ångest. "
		+ "Jag har slipat eggen själv — nu hugger den både träd och dåliga beslut."
	),
	"src_stiletto": (
		"SRC Stiletto! Smal, röd och corporate. "
		+ "Känns som att hugga någon med en powerpoint."
	),
	"redemption_blade": (
		"Redemption Blade! Tung, dyr och moraliskt tvetydig — "
		+ "precis som halva kolonin."
	),
	"zezzlor_gut_knife": (
		"Zezzlor Gut-Knife! Den här får inte ens hänga i fönstret utan särskilt tillstånd. "
		+ "Jag säljer den ändå. Det är varför jag heter Stål-Sven och inte Stål-Snäll."
	),
}


static func get_greeting() -> String:
	return GREETING


static func get_weapon_reaction(weapon_id: String) -> String:
	return str(REACTIONS.get(weapon_id, "Intressant val. Jag hade själv tagit något med mer gnista."))


static func get_weapon_summary(weapon_id: String) -> String:
	var name := ItemCatalog.get_display_name(weapon_id)
	var price := ItemCatalog.get_shop_price(weapon_id)
	var damage := int(WeaponCatalog.get_damage(weapon_id))
	var desc := ItemCatalog.get_description(weapon_id)
	var kind := "Närstrid" if WeaponCatalog.is_melee(weapon_id) else "Avstånd"
	return (
		"%s\n%s | %d skada | %d %s\n\n%s"
		% [name, kind, damage, price, ItemCatalog.currency_symbol(), desc]
	)


static func get_weapon_button_label(weapon_id: String) -> String:
	var name := ItemCatalog.get_display_name(weapon_id)
	var price := ItemCatalog.get_shop_price(weapon_id)
	var damage := int(WeaponCatalog.get_damage(weapon_id))
	return "%s — %d skada — %d %s" % [name, damage, price, ItemCatalog.currency_symbol()]