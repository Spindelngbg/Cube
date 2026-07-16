# Znood — avancerad utveckling (TODO)

Znood är kolonisternas personliga åtkomststämpel. Den sitter i **vänster hand närmast ansiktet** och används för att öppna säkerhetsdörrar. Nuvarande implementation är en **MVP**: enkel mesh, stämpelanimation och låsta dörrar utan fullständig identitetssynk.

## Nuvarande MVP (klar)

- [x] Znood-visual på spelaren (`AvatarPivot/ZnoodMount`)
- [x] Stämpel mot Znood-läsare med **[E]**
- [x] Fysiska dörrar vid SRC Annex, bostadstorn och hiss
- [x] Multiplayer-synk av upplåsning (RPC)

## Avancerat — TODO

### Identitet och säkerhet
- [ ] Koppla Znood till koloniprofil / `Profile.active_character_id`
- [ ] Säkerhetsnivåer (`standard`, `src_lab`, `federal`) per dörr
- [ ] Tillfällig återkallelse om SRC saboterar Znood-registret (story-event)
- [ ] Gästkonto får lånad engångs-Znood med timeout

### Animation och kropp
- [ ] Fäst Znood vid vänster pedipalp i `SpiderAlienBuilder` (dynamisk mount, inte fast offset)
- [ ] IK-animation: hand lyfts mot läsare vid stämpel
- [ ] Synlig holografisk bekräftelse på läsarpanel (grön/röd)
- [ ] Ljud: surr, klick, avvisning

### Nätverk och persistence
- [ ] Spara upplåsta dörrar per koloni i `user://` eller server
- [ ] OWDB-registrering av dörrstatus för multiplayer
- [ ] Stämpel-logg i questjournalen (tid, dörr-id, koloni)

### Gameplay och story
- [ ] SRC-vakter reagerar om spelare stämplar utan behörighet
- [ ] Stulen/förfalskad Znood som quest-item
- [ ] Znood-uppgradering efter Operation Redemption
- [ ] Integration med framtida inventory (**I**) — Znood som utrustningsplats

### Tekniskt
- [ ] Egen `ZnoodManager` autoload för central logik
- [ ] `scenes/access/znood_access_door.tscn` för redigerarvänlig placering
- [ ] Enhetstester för `can_stamp`, RPC och kollisionsblockering

## Referens i kod

| Fil | Syfte |
|-----|-------|
| `scripts/access/znood_device.gd` | Enhet på spelaren |
| `scripts/access/znood_access_door.gd` | Dörr + läsare |
| `scripts/access/znood_door_builder.gd` | Placeringshjälp |
| `scenes/player.tscn` → `ZnoodMount` | Mountpunkt vänster hand / ansikte |