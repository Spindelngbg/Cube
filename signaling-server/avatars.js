const crypto = require('crypto');
const path = require('path');
const {
	verifySession,
	validateUsername,
	readJsonBody,
	sendJson,
} = require('./auth');
const { DATA_DIR, writeJsonAtomic, readJsonFile } = require('./data-path');

const AVATARS_FILE = path.join(DATA_DIR, 'avatars.json');

const MAX_CHARACTERS_DEFAULT = 6;
const UNLIMITED_USER = 'testare1';
const COLOR_RE = /^#[0-9a-fA-F]{6}$/;
const CHARACTER_NAME_RE = /^[\p{L}\p{N} _-]{1,16}$/u;

function loadStore() {
	return readJsonFile(AVATARS_FILE, {});
}

function saveStore(data) {
	writeJsonAtomic(AVATARS_FILE, data);
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

	return {
		body_color: sanitizeColor(raw.body_color, '#1f2420'),
		accent_color: sanitizeColor(raw.accent_color, '#730c1e'),
		eye_color: sanitizeColor(raw.eye_color, '#f23326'),
		glow_color: sanitizeColor(raw.glow_color, '#cc2640'),
		body_scale: clamp(Number(raw.body_scale) || 1, 0.75, 1.5),
		abdomen_scale: clamp(Number(raw.abdomen_scale) || 1, 0.6, 1.6),
		head_scale: clamp(Number(raw.head_scale) || 1, 0.8, 1.4),
		leg_length: clamp(Number(raw.leg_length) || 1, 0.7, 1.5),
		arm_length: clamp(Number(raw.arm_length) || 1, 0.6, 1.4),
		spider_leg_count: Math.round(clamp(Number(raw.spider_leg_count) || 6, 4, 8)),
		eye_count: Math.round(clamp(Number(raw.eye_count) || 6, 2, 8)),
		eye_size: clamp(Number(raw.eye_size) || 1, 0.4, 2),
		mandible_length: clamp(Number(raw.mandible_length) || 1, 0, 2),
		chitin_roughness: clamp(Number(raw.chitin_roughness) || 0.55, 0, 1),
		chitin_metallic: clamp(Number(raw.chitin_metallic) || 0.15, 0, 1),
		glow_strength: clamp(Number(raw.glow_strength) || 0.6, 0, 2),
		spike_amount: clamp(Number(raw.spike_amount) || 0.35, 0, 1),
		stance_width: clamp(Number(raw.stance_width) || 1, 0.5, 1.5),
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
	if (character.nestVisited === undefined) {
		character.nestVisited = true;
	}
	return character;
}

function serializeCharacter(character) {
	const entry = migrateCharacter(character);
	return {
		id: entry.id,
		name: entry.name,
		avatar: entry.avatar,
		createdAt: entry.createdAt,
		updatedAt: entry.updatedAt,
		nestVisited: Boolean(entry.nestVisited),
	};
}

function listCharacters(username) {
	const userError = validateUsername(username);
	if (userError) {
		return { ok: false, error: userError };
	}

	const data = loadStore();
	const record = ensureUserRecord(data, username);
	record.characters = record.characters.map((entry) => migrateCharacter(entry));
	saveStore(data);
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
	if (req.method === 'OPTIONS' && (req.url.startsWith('/avatar/') || req.url.startsWith('/characters/'))) {
		sendJson(res, 204, {});
		return true;
	}

	if (req.method !== 'POST') {
		return false;
	}

	const isCharacterRoute = req.url.startsWith('/characters/');
	const isLegacyRoute = req.url.startsWith('/avatar/');
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

	if (req.url === '/characters/list' || req.url === '/avatar/load') {
		const auth = requireSession(body);
		if (!auth.ok) {
			sendJson(res, auth.status, { ok: false, error: auth.error });
			return true;
		}
		sendJson(res, 200, listCharacters(auth.session.username));
		return true;
	}

	if (req.url === '/characters/create') {
		const auth = requireSession(body);
		if (!auth.ok) {
			sendJson(res, auth.status, { ok: false, error: auth.error });
			return true;
		}
		sendJson(res, 200, createCharacter(auth.session.username, body.name));
		return true;
	}

	if (req.url === '/characters/save' || req.url === '/avatar/save') {
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

	if (req.url === '/characters/delete') {
		const auth = requireSession(body);
		if (!auth.ok) {
			sendJson(res, auth.status, { ok: false, error: auth.error });
			return true;
		}
		sendJson(res, 200, deleteCharacter(auth.session.username, body.id));
		return true;
	}

	if (req.url === '/characters/select') {
		const auth = requireSession(body);
		if (!auth.ok) {
			sendJson(res, auth.status, { ok: false, error: auth.error });
			return true;
		}
		sendJson(res, 200, selectCharacter(auth.session.username, body.id));
		return true;
	}

	if (req.url === '/characters/get' || req.url === '/avatar/get') {
		const username = typeof body.username === 'string' ? body.username.trim() : '';
		sendJson(res, 200, getActiveCharacter(username));
		return true;
	}

	if (req.url === '/characters/nest_complete') {
		const auth = requireSession(body);
		if (!auth.ok) {
			sendJson(res, auth.status, { ok: false, error: auth.error });
			return true;
		}
		const characterId = body.id || body.characterId;
		sendJson(res, 200, completeNestIntro(auth.session.username, characterId));
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