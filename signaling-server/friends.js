const { loadAccounts, validateUsername } = require('./auth');
const { getStore, setStore } = require('./persistence');

function loadFriendsData() {
	return getStore('friends', {});
}

function saveFriendsData(data) {
	setStore('friends', data);
}

function userKey(username) {
	return username.toLowerCase();
}

function ensureUserRecord(data, username) {
	const key = userKey(username);
	if (!data[key]) {
		data[key] = {
			username,
			friends: [],
			pendingIn: [],
			pendingOut: [],
		};
	}
	return data[key];
}

function accountExists(username) {
	const accounts = loadAccounts();
	return Boolean(accounts[userKey(username)]);
}

function sendFriendRequest(fromUser, toUser) {
	if (fromUser.toLowerCase() === toUser.toLowerCase()) {
		return { ok: false, error: 'Du kan inte lägga till dig själv' };
	}
	const fromError = validateUsername(fromUser);
	const toError = validateUsername(toUser);
	if (fromError || toError) {
		return { ok: false, error: 'Ogiltigt användarnamn' };
	}
	if (!accountExists(fromUser) || !accountExists(toUser)) {
		return { ok: false, error: 'Kontot finns inte' };
	}

	const data = loadFriendsData();
	const fromRecord = ensureUserRecord(data, fromUser);
	const toRecord = ensureUserRecord(data, toUser);
	const toKey = userKey(toUser);
	const fromKey = userKey(fromUser);

	if (fromRecord.friends.includes(toKey)) {
		return { ok: false, error: 'Ni är redan vänner' };
	}
	if (fromRecord.pendingOut.includes(toKey)) {
		return { ok: false, error: 'Vänförfrågan redan skickad' };
	}
	if (toRecord.pendingOut.includes(fromKey)) {
		return acceptFriendRequest(toUser, fromUser);
	}

	fromRecord.pendingOut.push(toKey);
	toRecord.pendingIn.push({
		from: fromUser,
		at: new Date().toISOString(),
	});
	saveFriendsData(data);

	return { ok: true, to: toUser };
}

function acceptFriendRequest(username, fromUser) {
	const data = loadFriendsData();
	const record = ensureUserRecord(data, username);
	const fromRecord = ensureUserRecord(data, fromUser);
	const fromKey = userKey(fromUser);
	const userK = userKey(username);

	record.pendingIn = record.pendingIn.filter((entry) => userKey(entry.from) !== fromKey);
	fromRecord.pendingOut = fromRecord.pendingOut.filter((name) => name !== userK);

	if (!record.friends.includes(fromKey)) {
		record.friends.push(fromKey);
	}
	if (!fromRecord.friends.includes(userK)) {
		fromRecord.friends.push(userK);
	}

	saveFriendsData(data);
	return { ok: true, friend: fromUser };
}

function declineFriendRequest(username, fromUser) {
	const data = loadFriendsData();
	const record = ensureUserRecord(data, username);
	const fromRecord = ensureUserRecord(data, fromUser);
	const fromKey = userKey(fromUser);
	const userK = userKey(username);

	record.pendingIn = record.pendingIn.filter((entry) => userKey(entry.from) !== fromKey);
	fromRecord.pendingOut = fromRecord.pendingOut.filter((name) => name !== userK);
	saveFriendsData(data);
	return { ok: true };
}

function getFriendsSnapshot(username) {
	const data = loadFriendsData();
	const record = ensureUserRecord(data, username);
	const accounts = loadAccounts();

	const friends = record.friends.map((key) => {
		const account = accounts[key];
		return account ? account.username : key;
	});

	const pendingIn = record.pendingIn.map((entry) => ({
		from: entry.from,
		at: entry.at,
	}));

	const pendingOut = record.pendingOut.map((key) => {
		const account = accounts[key];
		return account ? account.username : key;
	});

	return {
		friends,
		pendingIn,
		pendingOut,
	};
}

module.exports = {
	sendFriendRequest,
	acceptFriendRequest,
	declineFriendRequest,
	getFriendsSnapshot,
	accountExists,
};