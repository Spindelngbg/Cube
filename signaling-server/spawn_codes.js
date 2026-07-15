const crypto = require('crypto');
const { getStore, setStore } = require('./persistence');

const SPAWN_IDS = ['satellite_left', 'satellite_top_a', 'satellite_top_b', 'satellite_right'];
const LEGACY_SPAWN_MAP = {
	north_tower: 'satellite_top_a',
	south_hall: 'satellite_top_b',
	west_dock: 'satellite_left',
	east_gallery: 'satellite_right',
};

function normalizeSpawnId(spawnId) {
	if (SPAWN_IDS.includes(spawnId)) {
		return spawnId;
	}
	return LEGACY_SPAWN_MAP[spawnId] || '';
}
const CODE_COUNT = 100;
const STORE_KEY = 'spawn_codes';

function randomChunk(length) {
	const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
	let out = '';
	for (let i = 0; i < length; i++) {
		out += alphabet[crypto.randomInt(0, alphabet.length)];
	}
	return out;
}

function generateCode(index) {
	return `LJUS-${String(index + 1).padStart(3, '0')}-${randomChunk(4)}`;
}

function buildInitialCodes() {
	const codes = {};
	const used = new Set();
	let index = 0;
	while (Object.keys(codes).length < CODE_COUNT) {
		const code = generateCode(index);
		index += 1;
		if (used.has(code)) {
			continue;
		}
		used.add(code);
		const spawnId = SPAWN_IDS[Object.keys(codes).length % SPAWN_IDS.length];
		codes[code] = {
			spawnId,
			used: false,
			usedBy: null,
			usedCharacterId: null,
			usedAt: null,
		};
	}
	return codes;
}

function migrateCodes(codes) {
	let changed = false;
	for (const [code, entry] of Object.entries(codes)) {
		const normalized = normalizeSpawnId(entry.spawnId);
		if (normalized && normalized !== entry.spawnId) {
			entry.spawnId = normalized;
			changed = true;
		}
	}
	if (changed) {
		saveCodes(codes);
	}
	return codes;
}

function loadCodes() {
	let codes = getStore(STORE_KEY, null);
	if (!codes || typeof codes !== 'object' || Object.keys(codes).length < CODE_COUNT) {
		codes = buildInitialCodes();
		setStore(STORE_KEY, codes);
	}
	return migrateCodes(codes);
}

function saveCodes(codes) {
	setStore(STORE_KEY, codes);
}

function normalizeCode(raw) {
	if (typeof raw !== 'string') {
		return '';
	}
	return raw.trim().toUpperCase();
}

function redeemSecretCode(username, characterId, rawCode) {
	const code = normalizeCode(rawCode);
	if (!code) {
		return { ok: false, error: 'Ange en hemlig kod' };
	}

	const codes = loadCodes();
	const entry = codes[code];
	if (!entry) {
		return { ok: false, error: 'Ogiltig hemlig kod' };
	}
	if (entry.used) {
		return { ok: false, error: 'Koden har redan använts' };
	}
	if (!SPAWN_IDS.includes(entry.spawnId)) {
		return { ok: false, error: 'Koden pekar på en ogiltig spawn' };
	}

	entry.used = true;
	entry.usedBy = username;
	entry.usedCharacterId = characterId;
	entry.usedAt = new Date().toISOString();
	saveCodes(codes);

	return {
		ok: true,
		spawnId: entry.spawnId,
		code,
	};
}

function getCodeStats() {
	const codes = loadCodes();
	const values = Object.values(codes);
	return {
		total: values.length,
		used: values.filter((entry) => entry.used).length,
		available: values.filter((entry) => !entry.used).length,
	};
}

module.exports = {
	SPAWN_IDS,
	LEGACY_SPAWN_MAP,
	normalizeSpawnId,
	loadCodes,
	redeemSecretCode,
	getCodeStats,
	buildInitialCodes,
};