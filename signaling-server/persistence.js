const fs = require('fs');
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
	spawn_codes: 'spawn_codes.json',
};

const POSTGRES_INIT_TIMEOUT_MS = 8000;
const DATA_DIR_WRITE_TEST_TIMEOUT_MS = 3000;
const POSTGRES_QUERY_TIMEOUT_MS = 5000;

const cache = new Map();
let pool = null;
let backend = 'files';
let ready = false;
let dataDirWritable = false;
let persistenceWarning = '';

function isObject(value) {
	return value !== null && typeof value === 'object' && !Array.isArray(value);
}

function hasEntries(value) {
	return isObject(value) && Object.keys(value).length > 0;
}

function fileNameFor(storeKey) {
	return STORE_FILES[storeKey] || `${storeKey}.json`;
}

function filePathFor(storeKey) {
	return path.join(DATA_DIR, fileNameFor(storeKey));
}

async function verifyDataDirWritable() {
	try {
		ensureDataDir();
		const testPath = path.join(DATA_DIR, '.write_test');
		return await withTimeout(
			new Promise((resolve) => {
				fs.writeFile(testPath, new Date().toISOString(), 'utf8', (writeError) => {
					if (writeError) {
						resolve(false);
						return;
					}
					fs.unlink(testPath, () => resolve(true));
				});
			}),
			DATA_DIR_WRITE_TEST_TIMEOUT_MS,
			'DATA_DIR write test'
		);
	} catch (error) {
		console.error(`DATA_DIR not writable (${DATA_DIR}):`, error.message || error);
		return false;
	}
}

async function query(text, params) {
	return withTimeout(
		pool.query(text, params),
		POSTGRES_QUERY_TIMEOUT_MS,
		'PostgreSQL query'
	);
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
	const filePath = filePathFor(storeKey);
	setImmediate(() => {
		try {
			writeJsonAtomic(filePath, data);
		} catch (error) {
			console.error(`Failed to write ${filePath}:`, error);
		}
	});
}

function withTimeout(promise, timeoutMs, label) {
	return Promise.race([
		promise,
		new Promise((_, reject) => {
			setTimeout(() => reject(new Error(`${label} timed out after ${timeoutMs}ms`)), timeoutMs);
		}),
	]);
}

async function initPostgres() {
	const databaseUrl = process.env.DATABASE_URL;
	if (!databaseUrl) {
		return false;
	}

	const { Pool } = require('pg');
	pool = new Pool({
		connectionString: databaseUrl,
		connectionTimeoutMillis: POSTGRES_INIT_TIMEOUT_MS,
		query_timeout: POSTGRES_QUERY_TIMEOUT_MS,
		ssl: databaseUrl.includes('localhost') || databaseUrl.includes('127.0.0.1')
			? false
			: { rejectUnauthorized: false },
	});

	await withTimeout(
		query(`
			CREATE TABLE IF NOT EXISTS cube_store (
				store_key TEXT PRIMARY KEY,
				data JSONB NOT NULL,
				updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
			);
		`),
		POSTGRES_INIT_TIMEOUT_MS,
		'PostgreSQL init'
	);

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
			if (!hasEntries(data)) {
				const fromFile = loadFromFiles(storeKey, {});
				if (hasEntries(fromFile)) {
					data = fromFile;
				}
			}
		} else {
			data = loadFromFiles(storeKey, {});
		}
		cache.set(storeKey, data);
	}
}

function updatePersistenceWarning() {
	if (!dataDirWritable) {
		persistenceWarning = `DATA_DIR ${DATA_DIR} is not writable – accounts will not survive restarts`;
		return;
	}
	if (!process.env.DATABASE_URL && !process.env.RAILWAY_VOLUME_MOUNT_PATH) {
		persistenceWarning = 'No DATABASE_URL and no Railway volume detected – attach volume at /web or add PostgreSQL';
		return;
	}
	persistenceWarning = '';
}

async function initStorage() {
	if (ready) {
		return getStorageStatus();
	}

	ensureDataDir();
	dataDirWritable = await verifyDataDirWritable();

	try {
		const postgresReady = await initPostgres();
		if (postgresReady) {
			await migrateFilesToPostgres();
			console.log('PostgreSQL storage ready');
		} else {
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
	}

	await preloadStores();
	updatePersistenceWarning();
	ready = true;

	const status = getStorageStatus();
	console.log(`Persistence: backend=${status.backend}, accounts=${status.accountCount}, dataDir=${status.dataDir}, warning=${status.persistenceWarning || 'none'}`);
	return status;
}

function getStore(storeKey, fallback = {}) {
	if (!ready) {
		return loadFromFiles(storeKey, fallback);
	}
	if (cache.has(storeKey)) {
		return cache.get(storeKey);
	}
	const data = loadFromFiles(storeKey, fallback);
	cache.set(storeKey, data);
	return data;
}

function setStore(storeKey, data) {
	const payload = isObject(data) ? data : {};
	cache.set(storeKey, payload);

	// Alltid skriv till fil först – även när PostgreSQL används.
	saveToFiles(storeKey, payload);

	if (backend === 'postgres' && pool) {
		saveToPostgres(storeKey, payload).catch((error) => {
			console.error(`Failed to persist ${storeKey} to PostgreSQL:`, error);
		});
	}
}

async function flushStore(storeKey) {
	const payload = cache.get(storeKey);
	if (!isObject(payload)) {
		return;
	}
	try {
		writeJsonAtomic(filePathFor(storeKey), payload);
	} catch (error) {
		console.error(`Failed to flush ${storeKey} to files:`, error);
	}
	if (backend === 'postgres' && pool) {
		try {
			await saveToPostgres(storeKey, payload);
		} catch (error) {
			console.error(`Failed to flush ${storeKey} to PostgreSQL:`, error);
		}
	}
}

function getStorageStatus() {
	const accounts = getStore('accounts', {});
	return {
		ready,
		backend,
		dataDir: DATA_DIR,
		dataDirWritable,
		volumeMount: process.env.RAILWAY_VOLUME_MOUNT_PATH || null,
		databaseConfigured: Boolean(process.env.DATABASE_URL),
		accountCount: Object.keys(accounts).length,
		persistenceWarning,
	};
}

module.exports = {
	initStorage,
	getStore,
	setStore,
	flushStore,
	getStorageStatus,
};