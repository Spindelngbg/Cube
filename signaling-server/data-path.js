const fs = require('fs');
const path = require('path');

function resolveDataDir() {
	if (process.env.DATA_DIR) {
		return process.env.DATA_DIR;
	}
	if (process.env.RAILWAY_VOLUME_MOUNT_PATH) {
		return process.env.RAILWAY_VOLUME_MOUNT_PATH;
	}
	if (process.env.RAILWAY_ENVIRONMENT || process.env.RAILWAY_PROJECT_ID || process.env.RAILWAY_SERVICE_ID) {
		return '/web';
	}
	return path.join(__dirname, 'data');
}

const DATA_DIR = resolveDataDir();

function ensureDataDir() {
	if (!fs.existsSync(DATA_DIR)) {
		fs.mkdirSync(DATA_DIR, { recursive: true });
	}
}

function writeJsonAtomic(filePath, data) {
	ensureDataDir();
	const tmpPath = `${filePath}.tmp`;
	fs.writeFileSync(tmpPath, JSON.stringify(data, null, 2), 'utf8');
	fs.renameSync(tmpPath, filePath);
}

function readJsonFile(filePath, fallback) {
	ensureDataDir();
	if (!fs.existsSync(filePath)) {
		return fallback;
	}
	try {
		return JSON.parse(fs.readFileSync(filePath, 'utf8'));
	} catch (e) {
		console.error(`Failed to read ${filePath}:`, e);
		return fallback;
	}
}

module.exports = {
	DATA_DIR,
	ensureDataDir,
	writeJsonAtomic,
	readJsonFile,
};