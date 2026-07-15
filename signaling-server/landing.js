function renderLandingPage(host) {
	const wsUrl = host ? `wss://${host}` : 'wss://din-app.railway.app';
	const httpUrl = host ? `https://${host}` : 'https://din-app.railway.app';

	return `<!DOCTYPE html>
<html lang="sv">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Cube Server</title>
  <style>
    * { box-sizing: border-box; }
    body {
      margin: 0; min-height: 100vh; font-family: system-ui, sans-serif;
      background: #12151c; color: #e8ecf2; display: flex; justify-content: center; padding: 32px 16px;
    }
    .wrap { width: 100%; max-width: 640px; }
    .badge {
      display: inline-block; background: #14532d; color: #86efac;
      padding: 6px 12px; border-radius: 999px; font-size: .85rem; margin-bottom: 16px;
    }
    h1 { margin: 0 0 8px; font-size: 2.2rem; }
    p { color: #94a3b8; line-height: 1.6; }
    .card {
      background: #1e2430; border: 1px solid #334155; border-radius: 12px;
      padding: 20px; margin: 16px 0;
    }
    h2 { margin: 0 0 12px; font-size: 1.1rem; }
    code, .url {
      display: block; background: #0f172a; border: 1px solid #475569; border-radius: 8px;
      padding: 12px; font-family: Consolas, monospace; word-break: break-all; margin-top: 8px;
    }
    a.btn {
      display: inline-block; margin-top: 12px; margin-right: 8px; padding: 10px 16px;
      background: #3b82f6; color: white; text-decoration: none; border-radius: 8px;
    }
    a.btn.secondary { background: #475569; }
    ul { color: #cbd5e1; padding-left: 20px; }
    li { margin: 8px 0; }
  </style>
</head>
<body>
  <div class="wrap">
    <div class="badge">Online</div>
    <h1>Cube Server</h1>
    <p>Signaling-servern kör. Detta är <strong>inte</strong> själva spelet — Cube körs i Godot på din dator.</p>

    <div class="card">
      <h2>Anslut spelet</h2>
      <p>I Cube, på inloggningsskärmen, klistra in denna URL under <em>Server</em>:</p>
      <div class="url">${wsUrl}</div>
    </div>

    <div class="card">
      <h2>Admin</h2>
      <p>Hantera konton och se statistik:</p>
      <a class="btn" href="/spindeln">Öppna Spindeln (/spindeln)</a>
    </div>

    <div class="card">
      <h2>API</h2>
      <ul>
        <li><code>POST ${httpUrl}/auth/register</code> – skapa konto</li>
        <li><code>POST ${httpUrl}/auth/login</code> – logga in</li>
        <li><code>POST ${httpUrl}/auth/guest</code> – gästinloggning</li>
        <li><code>WS ${wsUrl}</code> – WebRTC signaling</li>
      </ul>
    </div>
  </div>
</body>
</html>`;
}

module.exports = { renderLandingPage };