const https = require('https');

function post(path, body) {
	return new Promise((resolve, reject) => {
		const data = JSON.stringify(body);
		const req = https.request(
			{
				hostname: 'cube-production-3d68.up.railway.app',
				path,
				method: 'POST',
				headers: {
					'Content-Type': 'application/json',
					'Content-Length': Buffer.byteLength(data),
				},
			},
			(res) => {
				let raw = '';
				res.on('data', (chunk) => { raw += chunk; });
				res.on('end', () => resolve({ status: res.statusCode, raw }));
			}
		);
		req.setTimeout(10000, () => reject(new Error('timeout')));
		req.on('error', reject);
		req.write(data);
		req.end();
	});
}

(async () => {
	const name = `apitest${Date.now().toString().slice(-6)}`;
	console.log('register', name);
	const reg = await post('/auth/register', { username: name, password: 'pass1234' });
	console.log(reg.status, reg.raw);
	const parsed = JSON.parse(reg.raw);
	if (!parsed.ok) return;
	const list = await post('/characters/list', { token: parsed.sessionToken });
	console.log('list', list.status, list.raw);
})().catch((e) => console.error('ERR', e));