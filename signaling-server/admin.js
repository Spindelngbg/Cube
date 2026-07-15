const crypto = require('crypto');
const { listAccounts, deleteAccount } = require('./auth');

const ADMIN_USER = process.env.ADMIN_USER || 'admin';
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || 'cube-admin';
const SESSION_COOKIE = 'cube_admin_session';
const SESSION_TTL_MS = 24 * 60 * 60 * 1000;

const sessions = new Map();

function parseCookies(req) {
	const header = req.headers.cookie || '';
	const out = {};
	header.split(';').forEach((part) => {
		const [key, ...rest] = part.trim().split('=');
		if (key) {
			out[key] = decodeURIComponent(rest.join('='));
		}
	});
	return out;
}

function getSession(req) {
	const token = parseCookies(req)[SESSION_COOKIE];
	if (!token || !sessions.has(token)) {
		return null;
	}
	const session = sessions.get(token);
	if (session.expiresAt < Date.now()) {
		sessions.delete(token);
		return null;
	}
	return session;
}

function createSession() {
	const token = crypto.randomBytes(32).toString('hex');
	sessions.set(token, { expiresAt: Date.now() + SESSION_TTL_MS });
	return token;
}

function destroySession(req) {
	const token = parseCookies(req)[SESSION_COOKIE];
	if (token) {
		sessions.delete(token);
	}
}

function sendHtml(res, status, html) {
	res.writeHead(status, { 'Content-Type': 'text/html; charset=utf-8' });
	res.end(html);
}

function redirect(res, location) {
	res.writeHead(302, { Location: location });
	res.end();
}

function readBody(req) {
	return new Promise((resolve, reject) => {
		let body = '';
		req.on('data', (chunk) => {
			body += chunk;
			if (body.length > 1e6) {
				reject(new Error('Body too large'));
				req.destroy();
			}
		});
		req.on('end', () => resolve(body));
		req.on('error', reject);
	});
}

function parseFormBody(body) {
	const out = {};
	body.split('&').forEach((pair) => {
		const [key, value] = pair.split('=').map(decodeURIComponent);
		if (key) {
			out[key.replace(/\+/g, ' ')] = (value || '').replace(/\+/g, ' ');
		}
	});
	return out;
}

function pageShell(title, content) {
	return `<!DOCTYPE html>
<html lang="sv">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>${title} – Cube</title>
  <style>
    * { box-sizing: border-box; }
    body {
      margin: 0; min-height: 100vh; font-family: system-ui, sans-serif;
      background: #1a1f28; color: #e8ecf2;
      display: flex; align-items: center; justify-content: center; padding: 24px;
    }
    .card {
      width: 100%; max-width: 520px; background: #242b36;
      border: 1px solid #334155; border-radius: 12px; padding: 28px;
      box-shadow: 0 12px 40px rgba(0,0,0,.35);
    }
    h1 { margin: 0 0 8px; font-size: 1.75rem; }
    p { color: #94a3b8; margin: 0 0 20px; }
    label { display: block; margin: 14px 0 6px; font-size: .9rem; color: #cbd5e1; }
    input {
      width: 100%; padding: 10px 12px; border-radius: 8px; border: 1px solid #475569;
      background: #111827; color: #f8fafc; font-size: 1rem;
    }
    .password-row { display: flex; gap: 8px; align-items: center; }
    .password-row input { flex: 1; }
    button, .btn {
      margin-top: 18px; padding: 10px 16px; border: 0; border-radius: 8px;
      background: #3b82f6; color: white; font-size: 1rem; cursor: pointer;
      text-decoration: none; display: inline-block;
    }
    button.secondary, .btn.secondary { background: #475569; }
    .error { color: #f87171; margin-top: 12px; }
    table { width: 100%; border-collapse: collapse; margin-top: 16px; }
    th, td { text-align: left; padding: 10px 8px; border-bottom: 1px solid #334155; }
    th { color: #94a3b8; font-weight: 600; font-size: .85rem; }
    .stats { display: grid; grid-template-columns: repeat(3, 1fr); gap: 12px; margin: 16px 0; }
    .stat { background: #111827; border-radius: 8px; padding: 12px; }
    .stat strong { display: block; font-size: 1.4rem; }
    .stat span { color: #94a3b8; font-size: .85rem; }
    form.inline { display: inline; margin: 0; }
    form.inline button { margin: 0; padding: 6px 10px; font-size: .85rem; background: #dc2626; }
    .topbar { display: flex; justify-content: space-between; align-items: center; gap: 12px; }
  </style>
</head>
<body>
  <div class="card">${content}</div>
  <script>
    function togglePassword(inputId, btn) {
      const input = document.getElementById(inputId);
      const hidden = input.type === 'password';
      input.type = hidden ? 'text' : 'password';
      btn.textContent = hidden ? 'Dölj' : 'Visa';
    }
  </script>
</body>
</html>`;
}

function loginPage(error = '') {
	const errorHtml = error ? `<p class="error">${error}</p>` : '';
	return pageShell('Spindeln', `
    <h1>Spindeln</h1>
    <p>Admin-inloggning för Cube</p>
    <form method="POST" action="/spindeln/login">
      <label for="username">Användarnamn</label>
      <input id="username" name="username" autocomplete="username" required />
      <label for="password">Lösenord</label>
      <div class="password-row">
        <input id="password" name="password" type="password" autocomplete="current-password" required />
        <button type="button" class="secondary" onclick="togglePassword('password', this)">Visa</button>
      </div>
      ${errorHtml}
      <button type="submit">Logga in</button>
    </form>
  `);
}

function panelPage(stats, accounts) {
	const rows = accounts.length === 0
		? '<tr><td colspan="3">Inga konton ännu</td></tr>'
		: accounts.map((account) => `
      <tr>
        <td>${account.username}</td>
        <td>${account.createdAt || '–'}</td>
        <td>
          <form class="inline" method="POST" action="/spindeln/delete-account">
            <input type="hidden" name="username" value="${account.username}" />
            <button type="submit" onclick="return confirm('Ta bort ${account.username}?')">Ta bort</button>
          </form>
        </td>
      </tr>
    `).join('');

	return pageShell('Spindeln – Panel', `
    <div class="topbar">
      <div>
        <h1>Spindeln</h1>
        <p>Admin-panel</p>
      </div>
      <form method="POST" action="/spindeln/logout">
        <button type="submit" class="secondary">Logga ut</button>
      </form>
    </div>
    <div class="stats">
      <div class="stat"><strong>${stats.peersCount}</strong><span>Peers</span></div>
      <div class="stat"><strong>${stats.lobbyCount}</strong><span>Lobbies</span></div>
      <div class="stat"><strong>${accounts.length}</strong><span>Konton</span></div>
    </div>
    <table>
      <thead>
        <tr><th>Användarnamn</th><th>Skapad</th><th>Åtgärd</th></tr>
      </thead>
      <tbody>${rows}</tbody>
    </table>
  `);
}

async function handleAdminRequest(req, res, getStats) {
	const pathname = (req.url || '').split('?')[0];

	if (pathname === '/spindeln' && req.method === 'GET') {
		if (getSession(req)) {
			redirect(res, '/spindeln/panel');
			return true;
		}
		const params = new URL(req.url, 'http://localhost').searchParams;
		sendHtml(res, 200, loginPage(params.get('error') || ''));
		return true;
	}

	if (pathname === '/spindeln/login' && req.method === 'POST') {
		const body = await readBody(req);
		const form = parseFormBody(body);
		if (form.username === ADMIN_USER && form.password === ADMIN_PASSWORD) {
			const token = createSession();
			res.writeHead(302, {
				Location: '/spindeln/panel',
				'Set-Cookie': `${SESSION_COOKIE}=${token}; HttpOnly; Path=/; Max-Age=${SESSION_TTL_MS / 1000}; SameSite=Lax`,
			});
			res.end();
			return true;
		}
		redirect(res, '/spindeln?error=Fel+användarnamn+eller+lösenord');
		return true;
	}

	if (pathname === '/spindeln/logout' && req.method === 'POST') {
		destroySession(req);
		res.writeHead(302, {
			Location: '/spindeln',
			'Set-Cookie': `${SESSION_COOKIE}=; HttpOnly; Path=/; Max-Age=0; SameSite=Lax`,
		});
		res.end();
		return true;
	}

	if (pathname === '/spindeln/panel' && req.method === 'GET') {
		if (!getSession(req)) {
			redirect(res, '/spindeln');
			return true;
		}
		sendHtml(res, 200, panelPage(getStats(), listAccounts()));
		return true;
	}

	if (pathname === '/spindeln/delete-account' && req.method === 'POST') {
		if (!getSession(req)) {
			redirect(res, '/spindeln');
			return true;
		}
		const body = await readBody(req);
		const form = parseFormBody(body);
		deleteAccount(form.username);
		redirect(res, '/spindeln/panel');
		return true;
	}

	return false;
}

module.exports = {
	handleAdminRequest,
	ADMIN_USER,
};