const path = require('path');
const {
	DATA_DIR,
	ensureDataDir,
	writeJsonAtomic,
	readJsonFile,
} = require('./data-path');

const STORE_FILES = {
	accounts: 'accounts.json',
	sessions: 'sessions.json',
	avatars: 'avatars.json',
	friends: 'friends.json',
};

const cache = new Map();
let pool = null;
let backend = 'files';
let ready = false;

function isObject(value) {
	return value !== null && typeof value === 'object' && !Array.isArray(value);
}

function hasEntries(value) {
	return isObject(value) && Object.keys(value).length > 0;
}

function filePathFor(storeKey) {
	return path.join(DATA_DIR, STORE_FILES[storeKey]);
}

async function query(text, params) {
	return pool.query(text, params);
}

async function loadFromPostgres(storeKey) {
	const result = await query('SELECT data FROM cube_store WHERE store_key = $1', [storeKey]);
	if (result.rows.length === 0) {
		return null;
	}
	return result.rows[0].data;
}

async function saveToPostgres(storeKey, data) {
	await query(
		`INSERT INTO cube_store (store_key, data, updated_at)
		 VALUES ($1, $2, NOW())
		 ON CONFLICT (store_key)
		 DO UPDATE SET data = EXCLUDED.data, updated_at = NOW()`,
		[storeKey, data]
	);
}

function loadFromFiles(storeKey, fallback) {
	return readJsonFile(filePathFor(storeKey), fallback);
}

function saveToFiles(storeKey, data) {
	writeJsonAtomic(filePathFor(storeKey), data);
}

async function initPostgres() {
	const databaseUrl = process.env.DATABASE_URL;
	if (!databaseUrl) {
		return false;
	}

	const { Pool } = require('pg');
	pool = new Pool({
		connectionString: databaseUrl,
		ssl: databaseUrl.includes('localhost') || databaseUrl.includes('127.0.0.1')
			? false
			: { rejectUnauthorized: false },
	});

	await query(`
		CREATE TABLE IF NOT EXISTS cube_store (
			store_key TEXT PRIMARY KEY,
			data JSONB NOT NULL,
			updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
		);
	`);

	backend = 'postgres';
	return true;
}

async function migrateFilesToPostgres() {
	for (const storeKey of Object.keys(STORE_FILES)) {
		const existing = await loadFromPostgres(storeKey);
		if (hasEntries(existing)) {
			continue;
		}

		const fromFile = loadFromFiles(storeKey, null);
		if (!hasEntries(fromFile)) {
			continue;
		}

		await saveToPostgres(storeKey, fromFile);
		console.log(`Migrated ${storeKey} from files to PostgreSQL`);
	}
}

async function preloadStores() {
	for (const storeKey of Object.keys(STORE_FILES)) {
		let data = {};
		if (backend === 'postgres') {
			const stored = await loadFromPostgres(storeKey);
			data = isObject(stored) ? stored : {};
		} else {
			data = loadFromFiles(storeKey, {});
		}
		cache.set(storeKey, data);
	}
}

async function initStorage() {
	if (ready) {
		return getStorageStatus();
	}

	try {
		const postgresReady = await initPostgres();
		if (postgresReady) {
			await migrateFilesToPostgres();
		} else {
			ensureDataDir();
			console.log(`No DATABASE_URL – using JSON files in ${DATA_DIR}`);
		}
	} catch (error) {
		console.error('PostgreSQL init failed, falling back to JSON files:', error);
		backend = 'files';
		if (pool) {
			try {
				await pool.end();
			} catch (endError) {
				console.error('Failed to close PostgreSQL pool:', endError);
			}
		}
		pool = null;
		ensureDataDir();
	}

	await preloadStores();
	ready = true;
	return getStorageStatus();
}

function getStore(storeKey, fallback = {}) {
	if (!ready) {
		return loadFromFiles(storeKey, fallback);
	}
	if (cache.has(storeKey)) {
		return cache.get(storeKey);
	}
	const data = fallback;
	cache.set(storeKey, data);
	return data;
}

function setStore(storeKey, data) {
	const payload = isObject(data) ? data : {};
	cache.set(storeKey, payload);

	if (backend === 'postgres' && pool) {
		saveToPostgres(storeKey, payload).catch((error) => {
			console.error(`Failed to persist ${storeKey} to PostgreSQL:`, error);
		});
		return;
	}

	saveToFiles(storeKey, payload);
}

function getStorageStatus() {
	const accounts = getStore('accounts', {});
	return {
		ready,
		backend,
		dataDir: DATA_DIR,
		volumeMount: process.env.RAILWAY_VOLUME_MOUNT_PATH || null,
		databaseConfigured: Boolean(process.env.DATABASE_URL),
		accountCount: Object.keys(accounts).length,
	};
}

module.exports = {
	initStorage,
	getStore,
	setStore,
	getStorageStatus,
};