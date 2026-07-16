const crypto = require('crypto');
const {
	verifySession,
	validateUsername,
	readJsonBody,
	sendJson,
} = require('./auth');
const { getStore, setStore } = require('./persistence');
const { redeemSecretCode, SPAWN_IDS, normalizeSpawnId } = require('./spawn_codes');

const MAX_CHARACTERS_DEFAULT = 6;
const UNLIMITED_USER = 'testare1';
const COLOR_RE = /^#[0-9a-fA-F]{6}$/;
const MESH_ID_RE = /^[a-z0-9_-]{2,32}$/;
const CHARACTER_NAME_RE = /^[\p{L}\p{N} _-]{1,16}$/u;

function loadStore() {
	return getStore('avatars', {});
}

function saveStore(data) {
	setStore('avatars', data);
}

function getCharacterLimit(username) {
	return username.toLowerCase() === UNLIMITED_USER ? Infinity : MAX_CHARACTERS_DEFAULT;
}

function isUnlimitedUser(username) {
	return username.toLowerCase() === UNLIMITED_USER;
}

function generateCharacterId() {
	return `c_${crypto.randomBytes(8).toString('hex')}`;
}

function clamp(value, min, max) {
	return Math.min(max, Math.max(min, value));
}

function sanitizeColor(value, fallback) {
	if (typeof value !== 'string' || !COLOR_RE.test(value)) {
		return fallback;
	}
	return value;
}

function sanitizeAvatar(raw) {
	if (!raw || typeof raw !== 'object') {
		return null;
	}

	const mesh_id = typeof raw.mesh_id === 'string' && MESH_ID_RE.test(raw.mesh_id)
		? raw.mesh_id.slice(0, 32)
		: 'character-a';

	return {
		mesh_id,
		body_color: sanitizeColor(raw.body_color, '#121a0f'),
		accent_color: sanitizeColor(raw.accent_color, '#850f24'),
		eye_color: sanitizeColor(raw.eye_color, '#fa381f'),
		glow_color: sanitizeColor(raw.glow_color, '#e52e47'),
		body_scale: clamp(Number(raw.body_scale) || 1.08, 0.75, 1.5),
		abdomen_scale: clamp(Number(raw.abdomen_scale) || 1.12, 0.6, 1.6),
		head_scale: clamp(Number(raw.head_scale) || 1.05, 0.8, 1.4),
		leg_length: clamp(Number(raw.leg_length) || 1.05, 0.7, 1.5),
		arm_length: clamp(Number(raw.arm_length) || 1.08, 0.6, 1.4),
		spider_leg_count: Math.round(clamp(Number(raw.spider_leg_count) || 8, 4, 12)),
		eye_count: Math.round(clamp(Number(raw.eye_count) || 8, 2, 12)),
		eye_size: clamp(Number(raw.eye_size) || 1.2, 0.4, 3),
		eye_spread: clamp(Number(raw.eye_spread) || 1.15, 0.4, 2),
		eye_stalk_length: clamp(Number(raw.eye_stalk_length) || 0.55, 0, 1.5),
		mandible_length: clamp(Number(raw.mandible_length) || 1.25, 0, 2),
		fang_length: clamp(Number(raw.fang_length) || 1.1, 0, 2.5),
		claw_size: clamp(Number(raw.claw_size) || 0.85, 0, 2),
		abdomen_segments: clamp(Number(raw.abdomen_segments) || 0.62, 0, 1),
		crest_size: clamp(Number(raw.crest_size) || 0.42, 0, 1),
		chitin_roughness: clamp(Number(raw.chitin_roughness) || 0.48, 0, 1),
		chitin_metallic: clamp(Number(raw.chitin_metallic) || 0.22, 0, 1),
		glow_strength: clamp(Number(raw.glow_strength) || 0.85, 0, 2),
		spike_amount: clamp(Number(raw.spike_amount) || 0.58, 0, 1),
		stance_width: clamp(Number(raw.stance_width) || 1.08, 0.5, 1.5),
	};
}

function defaultAvatar() {
	return sanitizeAvatar({});
}

function sanitizeCharacterName(name, fallback) {
	if (typeof name !== 'string') {
		return fallback;
	}
	const trimmed = name.trim().slice(0, 16);
	if (!CHARACTER_NAME_RE.test(trimmed)) {
		return fallback;
	}
	return trimmed;
}

function migrateUserRecord(entry, username) {
	if (entry.characters && Array.isArray(entry.characters)) {
		return entry;
	}

	const avatar = entry.avatar ? sanitizeAvatar(entry.avatar) : defaultAvatar();
	const id = generateCharacterId();
	return {
		username,
		activeId: id,
		characters: [{
			id,
			name: 'Karaktär 1',
			avatar,
			createdAt: entry.updatedAt || new Date().toISOString(),
			updatedAt: entry.updatedAt || new Date().toISOString(),
		}],
	};
}

function ensureUserRecord(data, username) {
	const key = username.toLowerCase();
	if (!data[key]) {
		data[key] = {
			username,
			activeId: '',
			characters: [],
		};
	}
	data[key] = migrateUserRecord(data[key], username);
	return data[key];
}

function migrateCharacter(character) {
	if (character.avatar === undefined || character.avatar === null) {
		character.avatar = defaultAvatar();
	}
	if (character.avatarConfigured === undefined) {
		const createdAt = character.createdAt || '';
		const updatedAt = character.updatedAt || '';
		character.avatarConfigured = Boolean(
			character.homeSpawnLocked
			|| character.nestVisited
			|| (createdAt && updatedAt && updatedAt !== createdAt)
		);
	}
	if (character.nestVisited === undefined) {
		character.nestVisited = false;
	}
	if (character.homeSpawnLocked === undefined) {
		character.homeSpawnLocked = false;
	}
	if (character.homeSpawnMethod === undefined) {
		character.homeSpawnMethod = '';
	}
	if (!character.homeSpawnLocked) {
		character.homeSpawnId = '';
		character.homeSpawnMethod = '';
	} else if (character.homeSpawnId === undefined) {
		character.homeSpawnId = '';
	}
	if (character.homeSpawnId) {
		const normalized = normalizeSpawnId(character.homeSpawnId);
		if (normalized) {
			character.homeSpawnId = normalized;
		} else {
			character.homeSpawnId = '';
			character.homeSpawnLocked = false;
			character.homeSpawnMethod = '';
		}
	}
	return character;
}

function serializeCharacter(character) {
	const entry = migrateCharacter(character);
	return {
		id: entry.id,
		name: entry.name,
		avatar: entry.avatar,
		avatarConfigured: Boolean(entry.avatarConfigured),
		createdAt: entry.createdAt,
		updatedAt: entry.updatedAt,
		nestVisited: Boolean(entry.nestVisited),
		homeSpawnId: entry.homeSpawnId || '',
		homeSpawnLocked: Boolean(entry.homeSpawnLocked),
		homeSpawnMethod: entry.homeSpawnMethod || '',
	};
}

function listCharacters(username) {
	const userError = validateUsername(username);
	if (userError) {
		return { ok: false, error: userError };
	}

	const data = loadStore();
	const record = ensureUserRecord(data, username);
	const limit = getCharacterLimit(username);

	return {
		ok: true,
		characters: record.characters.map(serializeCharacter),
		activeId: record.activeId,
		count: record.characters.length,
		limit: Number.isFinite(limit) ? limit : null,
		unlimited: isUnlimitedUser(username),
	};
}

function canCreateCharacter(record, username) {
	const limit = getCharacterLimit(username);
	return record.characters.length < limit;
}

function createCharacter(username, rawName) {
	const userError = validateUsername(username);
	if (userError) {
		return { ok: false, error: userError };
	}

	const data = loadStore();
	const record = ensureUserRecord(data, username);
	if (!canCreateCharacter(record, username)) {
		return { ok: false, error: 'Max antal karaktärer uppnått (6)' };
	}

	const id = generateCharacterId();
	const name = sanitizeCharacterName(rawName, `Karaktär ${record.characters.length + 1}`);
	const now = new Date().toISOString();
	const character = migrateCharacter({
		id,
		name,
		avatar: defaultAvatar(),
		avatarConfigured: false,
		createdAt: now,
		updatedAt: now,
		nestVisited: false,
	});
	record.characters.push(character);
	if (!record.activeId) {
		record.activeId = id;
	}
	saveStore(data);

	return {
		ok: true,
		character: serializeCharacter(character),
		activeId: record.activeId,
	};
}

function findCharacter(record, characterId) {
	return record.characters.find((entry) => entry.id === characterId) || null;
}

function saveCharacter(username, characterId, avatarRaw) {
	const userError = validateUsername(username);
	if (userError) {
		return { ok: false, error: userError };
	}
	if (typeof characterId !== 'string' || characterId.length === 0) {
		return { ok: false, error: 'Ogiltigt karaktärs-id' };
	}

	const avatar = sanitizeAvatar(avatarRaw);
	if (!avatar) {
		return { ok: false, error: 'Ogiltig avatar-data' };
	}

	const data = loadStore();
	const record = ensureUserRecord(data, username);
	const character = findCharacter(record, characterId);
	if (!character) {
		return { ok: false, error: 'Karaktären finns inte' };
	}

	character.avatar = avatar;
	character.avatarConfigured = true;
	character.updatedAt = new Date().toISOString();
	saveStore(data);

	return { ok: true, character: serializeCharacter(character) };
}

function renameCharacter(username, characterId, rawName) {
	const data = loadStore();
	const record = ensureUserRecord(data, username);
	const character = findCharacter(record, characterId);
	if (!character) {
		return { ok: false, error: 'Karaktären finns inte' };
	}
	character.name = sanitizeCharacterName(rawName, character.name);
	character.updatedAt = new Date().toISOString();
	saveStore(data);
	return { ok: true, character: serializeCharacter(character) };
}

function deleteCharacter(username, characterId) {
	const data = loadStore();
	const record = ensureUserRecord(data, username);
	const index = record.characters.findIndex((entry) => entry.id === characterId);
	if (index === -1) {
		return { ok: false, error: 'Karaktären finns inte' };
	}

	record.characters.splice(index, 1);
	if (record.activeId === characterId) {
		record.activeId = record.characters[0] ? record.characters[0].id : '';
	}
	saveStore(data);

	return {
		ok: true,
		activeId: record.activeId,
		characters: record.characters.map(serializeCharacter),
	};
}

function selectCharacter(username, characterId) {
	const data = loadStore();
	const record = ensureUserRecord(data, username);
	const character = findCharacter(record, characterId);
	if (!character) {
		return { ok: false, error: 'Karaktären finns inte' };
	}
	record.activeId = characterId;
	saveStore(data);
	return {
		ok: true,
		activeId: characterId,
		character: serializeCharacter(character),
	};
}

function completeNestIntro(username, characterId) {
	const data = loadStore();
	const record = ensureUserRecord(data, username);
	const character = findCharacter(record, characterId);
	if (!character) {
		return { ok: false, error: 'Karaktären finns inte' };
	}
	migrateCharacter(character);
	character.nestVisited = true;
	character.updatedAt = new Date().toISOString();
	saveStore(data);
	return { ok: true, character: serializeCharacter(character) };
}

function setHomeSpawn(username, characterId, spawnId, method) {
	const normalizedSpawnId = normalizeSpawnId(spawnId);
	if (!SPAWN_IDS.includes(normalizedSpawnId)) {
		return { ok: false, error: 'Ogiltig spawnpunkt' };
	}
	if (!['elevator', 'secret_code'].includes(method)) {
		return { ok: false, error: 'Ogiltig spawnmetod' };
	}

	const data = loadStore();
	const record = ensureUserRecord(data, username);
	const character = findCharacter(record, characterId);
	if (!character) {
		return { ok: false, error: 'Karaktären finns inte' };
	}
	migrateCharacter(character);
	if (character.homeSpawnLocked) {
		return { ok: false, error: 'Ditt hem är redan valt och kan inte ändras' };
	}

	character.homeSpawnId = normalizedSpawnId;
	character.homeSpawnLocked = true;
	character.homeSpawnMethod = method;
	character.updatedAt = new Date().toISOString();
	saveStore(data);

	return { ok: true, character: serializeCharacter(character), spawnId: normalizedSpawnId };
}

function redeemHomeSecretCode(username, characterId, code) {
	const data = loadStore();
	const record = ensureUserRecord(data, username);
	const character = findCharacter(record, characterId);
	if (!character) {
		return { ok: false, error: 'Karaktären finns inte' };
	}
	migrateCharacter(character);
	if (character.homeSpawnLocked) {
		return { ok: false, error: 'Ditt hem är redan valt och kan inte ändras' };
	}

	const redeemed = redeemSecretCode(username, characterId, code);
	if (!redeemed.ok) {
		return redeemed;
	}

	character.homeSpawnId = redeemed.spawnId;
	character.homeSpawnLocked = true;
	character.homeSpawnMethod = 'secret_code';
	character.updatedAt = new Date().toISOString();
	saveStore(data);

	return {
		ok: true,
		character: serializeCharacter(character),
		spawnId: redeemed.spawnId,
		code: redeemed.code,
	};
}

function getActiveCharacter(username) {
	const userError = validateUsername(username);
	if (userError) {
		return { ok: false, error: userError };
	}

	const data = loadStore();
	const key = username.toLowerCase();
	const record = data[key];
	if (!record) {
		return { ok: true, avatar: null, characterName: '', characterId: '' };
	}

	const migrated = migrateUserRecord(record, username);
	data[key] = migrated;
	saveStore(data);

	const active = findCharacter(migrated, migrated.activeId) || migrated.characters[0] || null;
	if (!active) {
		return { ok: true, avatar: null, characterName: '', characterId: '' };
	}

	return {
		ok: true,
		username: migrated.username,
		characterId: active.id,
		characterName: active.name,
		avatar: active.avatar,
		updatedAt: active.updatedAt,
	};
}

function deleteAvatar(username) {
	const data = loadStore();
	delete data[username.toLowerCase()];
	saveStore(data);
}

function requireSession(body) {
	const token = typeof body.token === 'string' ? body.token : '';
	const session = verifySession(token);
	if (!session || session.isGuest) {
		return { ok: false, status: 401, error: 'Logga in med konto' };
	}
	return { ok: true, session };
}

async function handleAvatarRequest(req, res) {
	const pathname = (req.url || '').split('?')[0];

	if (req.method === 'OPTIONS' && (pathname.startsWith('/avatar/') || pathname.startsWith('/characters/'))) {
		sendJson(res, 204, {});
		return true;
	}

	if (req.method !== 'POST') {
		return false;
	}

	const isCharacterRoute = pathname.startsWith('/characters/');
	const isLegacyRoute = pathname.startsWith('/avatar/');
	if (!isCharacterRoute && !isLegacyRoute) {
		return false;
	}

	let body = {};
	try {
		body = await readJsonBody(req);
	} catch (e) {
		sendJson(res, 400, { ok: false, error: e.message });
		return true;
	}

	if (pathname === '/characters/list' || pathname === '/avatar/load') {
		const auth = requireSession(body);
		if (!auth.ok) {
			sendJson(res, auth.status, { ok: false, error: auth.error });
			return true;
		}
		sendJson(res, 200, listCharacters(auth.session.username));
		return true;
	}

	if (pathname === '/characters/create') {
		const auth = requireSession(body);
		if (!auth.ok) {
			sendJson(res, auth.status, { ok: false, error: auth.error });
			return true;
		}
		sendJson(res, 200, createCharacter(auth.session.username, body.name));
		return true;
	}

	if (pathname === '/characters/save' || pathname === '/avatar/save') {
		const auth = requireSession(body);
		if (!auth.ok) {
			sendJson(res, auth.status, { ok: false, error: auth.error });
			return true;
		}
		const characterId = body.id || body.characterId;
		if (!characterId) {
			const created = createCharacter(auth.session.username, body.name || 'Karaktär');
			if (!created.ok) {
				sendJson(res, 400, created);
				return true;
			}
			sendJson(res, 200, saveCharacter(auth.session.username, created.character.id, body.avatar));
			return true;
		}
		sendJson(res, 200, saveCharacter(auth.session.username, characterId, body.avatar));
		return true;
	}

	if (pathname === '/characters/delete') {
		const auth = requireSession(body);
		if (!auth.ok) {
			sendJson(res, auth.status, { ok: false, error: auth.error });
			return true;
		}
		sendJson(res, 200, deleteCharacter(auth.session.username, body.id));
		return true;
	}

	if (pathname === '/characters/select') {
		const auth = requireSession(body);
		if (!auth.ok) {
			sendJson(res, auth.status, { ok: false, error: auth.error });
			return true;
		}
		sendJson(res, 200, selectCharacter(auth.session.username, body.id));
		return true;
	}

	if (pathname === '/characters/get' || pathname === '/avatar/get') {
		const username = typeof body.username === 'string' ? body.username.trim() : '';
		sendJson(res, 200, getActiveCharacter(username));
		return true;
	}

	if (pathname === '/characters/nest_complete') {
		const auth = requireSession(body);
		if (!auth.ok) {
			sendJson(res, auth.status, { ok: false, error: auth.error });
			return true;
		}
		const characterId = body.id || body.characterId;
		sendJson(res, 200, completeNestIntro(auth.session.username, characterId));
		return true;
	}

	if (pathname === '/characters/set_home_spawn') {
		const auth = requireSession(body);
		if (!auth.ok) {
			sendJson(res, auth.status, { ok: false, error: auth.error });
			return true;
		}
		const characterId = body.id || body.characterId;
		sendJson(res, 200, setHomeSpawn(
			auth.session.username,
			characterId,
			body.spawnId,
			body.method || 'elevator'
		));
		return true;
	}

	if (pathname === '/characters/redeem_secret_code') {
		const auth = requireSession(body);
		if (!auth.ok) {
			sendJson(res, auth.status, { ok: false, error: auth.error });
			return true;
		}
		const characterId = body.id || body.characterId;
		sendJson(res, 200, redeemHomeSecretCode(
			auth.session.username,
			characterId,
			body.code
		));
		return true;
	}

	return false;
}

module.exports = {
	handleAvatarRequest,
	getActiveCharacter,
	deleteAvatar,
	sanitizeAvatar,
	listCharacters,
	createCharacter,
};