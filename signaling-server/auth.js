const crypto = require('crypto');
const { DATA_DIR } = require('./data-path');
const { getStore, setStore, flushStore } = require('./persistence');

const USERNAME_RE = /^[A-Za-z0-9_]{3,16}$/;
const MIN_PASSWORD_LEN = 4;
const SESSION_TTL_MS = 7 * 24 * 60 * 60 * 1000;

const sessions = new Map();

function loadSessions() {
	const stored = getStore('sessions', {});
	for (const [token, session] of Object.entries(stored)) {
		if (session && session.expires > Date.now()) {
			sessions.set(token, session);
		}
	}
}

function saveSessions() {
	const stored = {};
	for (const [token, session] of sessions.entries()) {
		if (session.expires > Date.now()) {
			stored[token] = session;
		}
	}
	setStore('sessions', stored);
}

function loadAccounts() {
	return getStore('accounts', {});
}

async function saveAccounts(accounts) {
	setStore('accounts', accounts);
	await flushStore('accounts');
}

function hashPassword(password) {
	const salt = crypto.randomBytes(16).toString('hex');
	const hash = crypto.scryptSync(password, salt, 64).toString('hex');
	return `${salt}:${hash}`;
}

function verifyPassword(password, stored) {
	const [salt, hash] = stored.split(':');
	if (!salt || !hash) {
		return false;
	}
	const check = crypto.scryptSync(password, salt, 64).toString('hex');
	return crypto.timingSafeEqual(Buffer.from(hash, 'hex'), Buffer.from(check, 'hex'));
}

function validateUsername(username) {
	if (typeof username !== 'string' || !USERNAME_RE.test(username)) {
		return 'Användarnamn måste vara 3–16 tecken (bokstäver, siffror, _)';
	}
	return null;
}

function createSession(username, isGuest) {
	const token = crypto.randomBytes(32).toString('hex');
	sessions.set(token, {
		username,
		isGuest: Boolean(isGuest),
		expires: Date.now() + SESSION_TTL_MS,
	});
	saveSessions();
	return token;
}

function verifySession(token) {
	if (typeof token !== 'string' || token.length === 0) {
		return null;
	}
	const session = sessions.get(token);
	if (!session) {
		return null;
	}
	if (session.expires < Date.now()) {
		sessions.delete(token);
		saveSessions();
		return null;
	}
	return session;
}

function validatePassword(password) {
	if (typeof password !== 'string' || password.length < MIN_PASSWORD_LEN) {
		return `Lösenord måste vara minst ${MIN_PASSWORD_LEN} tecken`;
	}
	return null;
}

async function register(username, password) {
	const userError = validateUsername(username);
	if (userError) {
		return { ok: false, error: userError };
	}
	const passError = validatePassword(password);
	if (passError) {
		return { ok: false, error: passError };
	}

	const accounts = loadAccounts();
	const key = username.toLowerCase();
	if (accounts[key]) {
		return { ok: false, error: 'Användarnamnet är redan taget' };
	}

	accounts[key] = {
		username,
		passwordHash: hashPassword(password),
		createdAt: new Date().toISOString(),
	};

	try {
		await saveAccounts(accounts);
	} catch (error) {
		console.error('Failed to persist account:', error);
		return { ok: false, error: 'Kunde inte spara kontot – försök igen' };
	}

	console.log(`Registered account: ${username} (total: ${Object.keys(accounts).length})`);

	const sessionToken = createSession(username, false);
	return {
		ok: true,
		username,
		isGuest: false,
		sessionToken,
	};
}

function login(username, password) {
	const userError = validateUsername(username);
	if (userError) {
		return { ok: false, error: userError };
	}
	if (typeof password !== 'string' || password.length === 0) {
		return { ok: false, error: 'Ange lösenord' };
	}

	const accounts = loadAccounts();
	const account = accounts[username.toLowerCase()];
	if (!account || !verifyPassword(password, account.passwordHash)) {
		return { ok: false, error: 'Fel användarnamn eller lösenord' };
	}

	const sessionToken = createSession(account.username, false);
	return {
		ok: true,
		username: account.username,
		isGuest: false,
		sessionToken,
	};
}

function guest() {
	const suffix = Math.floor(Math.random() * 9000) + 1000;
	const username = `Gäst_${suffix}`;
	const sessionToken = createSession(username, true);
	return {
		ok: true,
		username,
		isGuest: true,
		sessionToken,
	};
}

function readJsonBody(req) {
	return new Promise((resolve, reject) => {
		let body = '';
		req.on('data', (chunk) => {
			body += chunk;
			if (body.length > 1e6) {
				reject(new Error('Body too large'));
				req.destroy();
			}
		});
		req.on('end', () => {
			if (!body) {
				resolve({});
				return;
			}
			try {
				resolve(JSON.parse(body));
			} catch (e) {
				reject(new Error('Invalid JSON'));
			}
		});
		req.on('error', reject);
	});
}

function sendJson(res, status, payload) {
	res.writeHead(status, {
		'Content-Type': 'application/json',
		'Access-Control-Allow-Origin': '*',
		'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
		'Access-Control-Allow-Headers': 'Content-Type',
	});
	res.end(JSON.stringify(payload));
}

async function handleAuthRequest(req, res) {
	if (req.method === 'OPTIONS') {
		sendJson(res, 204, {});
		return true;
	}

	if (req.method !== 'POST') {
		return false;
	}

	const pathname = (req.url || '').split('?')[0];
	const isAuthRoute = pathname === '/auth/register'
		|| pathname === '/auth/login'
		|| pathname === '/auth/guest';
	if (!isAuthRoute) {
		return false;
	}

	let body = {};
	try {
		body = await readJsonBody(req);
	} catch (e) {
		sendJson(res, 400, { ok: false, error: e.message });
		return true;
	}

	if (pathname === '/auth/register') {
		sendJson(res, 200, await register(body.username, body.password));
		return true;
	}
	if (pathname === '/auth/login') {
		sendJson(res, 200, login(body.username, body.password));
		return true;
	}
	if (pathname === '/auth/guest') {
		sendJson(res, 200, guest());
		return true;
	}

	return false;
}

function listAccounts() {
	const accounts = loadAccounts();
	return Object.values(accounts)
		.map((account) => ({
			username: account.username,
			createdAt: account.createdAt || '',
		}))
		.sort((a, b) => a.username.localeCompare(b.username));
}

function deleteAccount(username) {
	if (typeof username !== 'string' || username.length === 0) {
		return { ok: false, error: 'Ogiltigt användarnamn' };
	}
	const accounts = loadAccounts();
	const key = username.toLowerCase();
	if (!accounts[key]) {
		return { ok: false, error: 'Kontot finns inte' };
	}
	delete accounts[key];
	saveAccounts(accounts);
	try {
		const { deleteAvatar } = require('./avatars');
		deleteAvatar(username);
	} catch (e) {
		console.error('Failed to delete avatar for account:', e);
	}
	return { ok: true };
}

function initPersistence() {
	loadSessions();
	const accountCount = Object.keys(loadAccounts()).length;
	console.log(`Loaded ${accountCount} account(s), ${sessions.size} session(s)`);
}

module.exports = {
	handleAuthRequest,
	register,
	login,
	guest,
	listAccounts,
	deleteAccount,
	loadAccounts,
	validateUsername,
	verifySession,
	createSession,
	readJsonBody,
	sendJson,
	initPersistence,
	DATA_DIR,
};