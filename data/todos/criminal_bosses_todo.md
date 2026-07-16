# Kriminella bossar — TODO

20 bossar (5 per koloni) med egna HQ långt från spawn. Respekt ökar främst genom samtal med bossen; syndikatmus blir trevligare när respekt stiger.

## Klart (MVP)

- [x] 20 bossar i `criminal_boss_catalog.gd` (5 × Koloni 1–4)
- [x] HQ-byggen långt från spawn (`criminal_boss_hq.gd`)
- [x] 4 syndikatmus utanför varje HQ (skittykna vid låg respekt)
- [x] Respekt 0–100 per boss, sparas per karaktär
- [x] Samtal med boss +8 respekt, med mus +2
- [x] Tonalitet: hostile → suspicious → neutral → respected

## TODO — gameplay

- [ ] Uppdrag från bossar när respekt ≥ 50 (smuggling, hämta paket, skydda HQ)
- [ ] Respekt via leveranser (Mydrillium, vapen, mineral) — alternativa vägar
- [ ] Respektförlust vid att döda syndikatmus eller stjäla från HQ
- [ ] Boss-rankning i Znood / questjournal
- [ ] Steam-achievements per syndikat

## TODO — värld & AI

- [ ] Unika HQ-varianter per boss (hamn, källare, tak, tunnel)
- [ ] Patrullerande bilar / drones runt HQ vid låg respekt
- [ ] Inbjudan inuti HQ när respekt ≥ 75 (interiör, loot, dialogträd)
- [ ] Rivaliserande syndikat som bråkar med varandra nära gränser
- [ ] Koloni 4: placera HQ i dedikerade DC-zoner med egen karta

## TODO — multiplayer

- [ ] Synka respekt via server / OWDB
- [ ] Visa annan spelares respektnivå för bossen i dialog
- [ ] PvP-regler vid HQ (vakt skjuter/slår vid låg respekt)

## TODO — polish

- [ ] Särskilda röster / barks per boss
- [ ] Rök, neonskyltar, graffiti per syndikat
- [ ] Minimap-markör för kända HQ efter första besök
- [ ] Tutorial-rad: "Långt från spawn finns syndikat — prata med cheferna"