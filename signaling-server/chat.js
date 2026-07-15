const WebSocket = require('ws');
const { verifySession, validateUsername } = require('./auth');
const {
	sendFriendRequest,
	acceptFriendRequest,
	declineFriendRequest,
	getFriendsSnapshot,
} = require('./friends');

const MAX_HISTORY = 120;
const MAX_MESSAGE_LEN = 400;
const VISITOR_PREFIX = 'Besökare_';

const chatHistory = [];
const onlineUsers = new Map();

function chatUrlFromHost(host) {
	if (!host) {
		return 'ws://localhost:9080/chat';
	}
	const cleanHost = host.split(',')[0].trim();
	return `wss://${cleanHost}/chat`;
}

function pushHistory(entry) {
	chatHistory.push(entry);
	if (chatHistory.length > MAX_HISTORY) {
		chatHistory.shift();
	}
	return entry;
}

function broadcast(payload, exceptWs = null) {
	const text = JSON.stringify(payload);
	for (const client of onlineUsers.values()) {
		if (client.ws.readyState === WebSocket.OPEN && client.ws !== exceptWs) {
			client.ws.send(text);
		}
	}
}

function send(ws, payload) {
	if (ws.readyState === WebSocket.OPEN) {
		ws.send(JSON.stringify(payload));
	}
}

function sanitizeText(text) {
	if (typeof text !== 'string') {
		return '';
	}
	return text.trim().slice(0, MAX_MESSAGE_LEN);
}

function isGuestName(username) {
	return username.startsWith('Gäst_') || username.startsWith(VISITOR_PREFIX);
}

function canUseFriends(client) {
	return client.identified && !client.isGuest;
}

function getOnlineFriends(usernames) {
	const online = new Set();
	for (const client of onlineUsers.values()) {
		if (client.identified) {
			online.add(client.username.toLowerCase());
		}
	}
	return usernames.map((name) => ({
		username: name,
		online: online.has(name.toLowerCase()),
	}));
}

function sendFriendsState(client) {
	if (!canUseFriends(client)) {
		send(client.ws, { type: 'friends', friends: [], pendingIn: [], pendingOut: [] });
		return;
	}
	const snapshot = getFriendsSnapshot(client.username);
	send(client.ws, {
		type: 'friends',
		friends: getOnlineFriends(snapshot.friends),
		pendingIn: snapshot.pendingIn,
		pendingOut: snapshot.pendingOut,
	});
}

function notifyFriendUsers(usernames) {
	const targets = new Set(usernames.map((name) => name.toLowerCase()));
	for (const client of onlineUsers.values()) {
		if (client.identified && targets.has(client.username.toLowerCase())) {
			sendFriendsState(client);
		}
	}
}

function identifyClient(client, body) {
	const username = typeof body.username === 'string' ? body.username.trim() : '';
	const token = typeof body.token === 'string' ? body.token : '';

	if (!username) {
		send(client.ws, { type: 'error', message: 'Ange användarnamn' });
		return;
	}

	const wasIdentified = client.identified;
	const previousUsername = client.username;

	let isGuest = false;
	if (isGuestName(username)) {
		isGuest = true;
	} else {
		const userError = validateUsername(username);
		if (userError) {
			send(client.ws, { type: 'error', message: userError });
			return;
		}
		const session = verifySession(token);
		if (!session || session.username.toLowerCase() !== username.toLowerCase()) {
			send(client.ws, { type: 'error', message: 'Ogiltig session – logga in igen' });
			return;
		}
		isGuest = session.isGuest;
	}

	client.username = username;
	client.identified = true;
	client.isGuest = isGuest;

	send(client.ws, {
		type: 'identified',
		username,
		isGuest,
		canFriends: !isGuest,
	});
	send(client.ws, { type: 'history', messages: chatHistory });
	sendFriendsState(client);

	if (wasIdentified && previousUsername.toLowerCase() === username.toLowerCase()) {
		return;
	}

	const joinText = isGuest
		? `${username} tittar förbi`
		: `${username} anslöt`;
	pushHistory({
		type: 'system',
		text: joinText,
		ts: Date.now(),
	});
	broadcast({
		type: 'system',
		text: joinText,
		ts: Date.now(),
	}, client.ws);
}

function handleChatMessage(client, body) {
	if (!client.identified) {
		send(client.ws, { type: 'error', message: 'Inte identifierad ännu' });
		return;
	}
	const text = sanitizeText(body.text);
	if (!text) {
		return;
	}

	const entry = pushHistory({
		type: 'message',
		username: client.username,
		text,
		ts: Date.now(),
	});
	broadcast(entry);
}

function handleFriendRequest(client, body) {
	if (!canUseFriends(client)) {
		send(client.ws, { type: 'error', message: 'Skapa konto för att lägga till vänner' });
		return;
	}
	const toUser = typeof body.to === 'string' ? body.to.trim() : '';
	const result = sendFriendRequest(client.username, toUser);
	if (!result.ok) {
		send(client.ws, { type: 'error', message: result.error });
		return;
	}

	send(client.ws, {
		type: 'system',
		text: `Vänförfrågan skickad till ${result.to}`,
		ts: Date.now(),
	});
	sendFriendsState(client);
	notifyFriendUsers([client.username, result.to]);

	for (const other of onlineUsers.values()) {
		if (other.identified && other.username.toLowerCase() === result.to.toLowerCase()) {
			send(other.ws, {
				type: 'friend_request',
				from: client.username,
				ts: Date.now(),
			});
			send(other.ws, {
				type: 'system',
				text: `${client.username} vill bli din vän`,
				ts: Date.now(),
			});
		}
	}
}

function handleFriendAccept(client, body) {
	if (!canUseFriends(client)) {
		send(client.ws, { type: 'error', message: 'Skapa konto för att hantera vänner' });
		return;
	}
	const fromUser = typeof body.from === 'string' ? body.from.trim() : '';
	const result = acceptFriendRequest(client.username, fromUser);
	if (!result.ok) {
		send(client.ws, { type: 'error', message: result.error || 'Kunde inte acceptera' });
		return;
	}

	send(client.ws, {
		type: 'system',
		text: `Du och ${result.friend} är nu vänner`,
		ts: Date.now(),
	});
	sendFriendsState(client);
	notifyFriendUsers([client.username, result.friend]);

	for (const other of onlineUsers.values()) {
		if (other.identified && other.username.toLowerCase() === result.friend.toLowerCase()) {
			send(other.ws, {
				type: 'friend_accepted',
				username: client.username,
				ts: Date.now(),
			});
			send(other.ws, {
				type: 'system',
				text: `${client.username} accepterade din vänförfrågan`,
				ts: Date.now(),
			});
			sendFriendsState(other);
		}
	}
}

function handleFriendDecline(client, body) {
	if (!canUseFriends(client)) {
		send(client.ws, { type: 'error', message: 'Skapa konto för att hantera vänner' });
		return;
	}
	const fromUser = typeof body.from === 'string' ? body.from.trim() : '';
	declineFriendRequest(client.username, fromUser);
	sendFriendsState(client);
	notifyFriendUsers([client.username, fromUser]);
}

function parseClientMessage(client, raw) {
	let body = null;
	try {
		body = JSON.parse(raw);
	} catch (e) {
		send(client.ws, { type: 'error', message: 'Ogiltigt meddelande' });
		return;
	}

	const type = typeof body.type === 'string' ? body.type : '';
	switch (type) {
	case 'identify':
		identifyClient(client, body);
		break;
	case 'chat':
		handleChatMessage(client, body);
		break;
	case 'friend_request':
		handleFriendRequest(client, body);
		break;
	case 'friend_accept':
		handleFriendAccept(client, body);
		break;
	case 'friend_decline':
		handleFriendDecline(client, body);
		break;
	case 'friends_refresh':
		sendFriendsState(client);
		break;
	default:
		send(client.ws, { type: 'error', message: 'Okänt kommando' });
	}
}

function attachChatServer() {
	const chatWss = new WebSocket.Server({ noServer: true });

	chatWss.on('connection', (ws) => {
		const client = {
			ws,
			username: '',
			identified: false,
			isGuest: true,
		};
		onlineUsers.set(ws, client);

		send(ws, {
			type: 'welcome',
			text: 'Ansluten till global chatt',
		});

		ws.on('message', (message, isBinary) => {
			if (isBinary) {
				return;
			}
			const text = typeof message === 'string' ? message : message.toString('utf8');
			parseClientMessage(client, text);
		});

		ws.on('close', () => {
			if (client.identified) {
				const leaveText = `${client.username} lämnade`;
				pushHistory({
					type: 'system',
					text: leaveText,
					ts: Date.now(),
				});
				broadcast({
					type: 'system',
					text: leaveText,
					ts: Date.now(),
				});
			}
			onlineUsers.delete(ws);
		});
	});

	return chatWss;
}

function getChatStats() {
	return {
		chatOnline: onlineUsers.size,
		chatHistory: chatHistory.length,
	};
}

module.exports = {
	attachChatServer,
	getChatStats,
	chatUrlFromHost,
	VISITOR_PREFIX,
};