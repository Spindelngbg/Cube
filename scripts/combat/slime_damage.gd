class_name SlimeDamage
extends RefCounted

## Inbyggd Slimeblaster på alla kroppar — frätande kolonist-slem.
const SHOTS_TO_KILL_NPC := 2
const NPC_MAX_HP := 100.0
const DAMAGE_PER_HIT := NPC_MAX_HP / float(SHOTS_TO_KILL_NPC)
const ZEZZLOR_MAX_HP := 500.0
const CORROSION_BUILDUP := 0.24
const BATON_DAMAGE := 14.0
const BATON_COOLDOWN := 1.1
const ZEZZLOR_SPEED := 5.8
const ZEZZLOR_COUNT := 4