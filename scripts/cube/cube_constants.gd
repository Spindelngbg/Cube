class_name CubeConstants
extends RefCounted

## Logical megastructure (NFT coordinate space).
## "30 mil" = 30 000 000 meter per axis.
const LOGICAL_EXTENT_M := 30_000_000.0
const LAYER_COUNT := 20
const BLOCKS_PER_AXIS := 30
const ZONES_PER_BLOCK_AXIS := 10

const LAYER_HEIGHT_M := LOGICAL_EXTENT_M / float(LAYER_COUNT)
const BLOCK_SIZE_M := LOGICAL_EXTENT_M / float(BLOCKS_PER_AXIS)
const ZONE_SIZE_M := BLOCK_SIZE_M / float(ZONES_PER_BLOCK_AXIS)
const TOTAL_ZONES := LAYER_COUNT * BLOCKS_PER_AXIS * BLOCKS_PER_AXIS * ZONES_PER_BLOCK_AXIS * ZONES_PER_BLOCK_AXIS

## Playable prototype slice inside the cube (layer 10, central district).
const PROTOTYPE_LAYER := 10
const PROTOTYPE_BLOCK_ORIGIN := Vector2i(13, 13)
const PROTOTYPE_BLOCK_COUNT := 5
const PROTOTYPE_METERS_PER_BLOCK := 40.0
const PROTOTYPE_METERS_PER_ZONE := 10.0
const PROTOTYPE_ZONES_PER_BLOCK := 4

const ZONE_ID_PATTERN := "L%02d-B%02d%02d-Z%d%d"

enum OwnershipStatus {
	FOUNDATION,
	PUBLIC,
	RESERVED,
	OWNED,
}

enum GovernanceStatus {
	FOUNDATION,
	OPEN,
	INTERIM,
	ELECTED,
	LOCKED,
}

enum TerritoryType {
	CUBE,
	LAYER,
	BLOCK,
	ZONE,
}