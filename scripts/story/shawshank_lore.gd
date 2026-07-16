class_name ShawshankLore
extends RefCounted

const COMPANY_NAME := "Shawshank Redemption Corp."
const COMPANY_SHORT := "SRC"
const PROJECT_NAME := "Projekt Redemption"
const SLOGAN := "Återlösen är inte frihet — det är ombyggnad."

const LEAKED_MEMO := (
	"INTERNT MEMO — LÄCKT\n"
	+ "Shawshank Redemption Corp. (SRC)\n\n"
	+ "Projekt Redemption förenar tre vävnadstyper i samma skal:\n"
	+ "• mänsklig kognitiv kärna\n"
	+ "• spindelreflexer och kollektiv jaktsignatur\n"
	+ "• robotchassi för fältöverlevnad\n\n"
	+ "Resultatet kallas inte längre 'patient'. Det kallas hybrid.\n"
	+ "När synken misslyckas blir de zombies — vandrande läckor.\n\n"
	+ "Koloni 4 används som fältlabb. Skydda inte företaget. Stoppa batcherna."
)

static func annex_sign() -> String:
	return hq_sign()


static func hq_sign() -> String:
	return (
		"%s\nHQ KOLONI-4\n%s\nSupermodern vit sandsten — [E] Granska ingång"
		% [COMPANY_NAME, PROJECT_NAME]
	)

const EVIDENCE_LOGS := [
	(
		"FIL 01 — REDEMPTION_BATCH_A\n"
		+ "Subjekt: människa (vilseförd kolonist)\n"
		+ "Implantat: spindelbensservonät + ögondrone-sensor\n"
		+ "Status: vaken men inte kontrollerbar. Klassad som zombie."
	),
	(
		"FIL 02 — REDEMPTION_BATCH_B\n"
		+ "Subjekt: stulen spindelunge från ljusrummet\n"
		+ "Implantat: mänskligt minneschip + pansarskal\n"
		+ "Notering: den sjunger barnvisor i morsekod."
	),
	(
		"FIL 03 — REDEMPTION_BATCH_C\n"
		+ "Subjekt: övergiven ögondrone\n"
		+ "Implantat: mänsklig hjärnstam + spindelgiftkörtlar\n"
		+ "Varning: vandrar mot spawn. Betraktas som lyckat 'redemption'-prov."
	),
]

const SABOTAGE_SUCCESS := (
	"UPPLADDNING KLAR — REDEMPTION SYNC AVBRUTEN\n\n"
	+ "Bevis skickade till koloninätverket. SRC:s batchkö är fryst.\n"
	+ "Hybridzombies kommer fortfarande vandra — men nya skapas inte här.\n\n"
	+ "Du har avslöjat Shawshank Redemption Corp."
)