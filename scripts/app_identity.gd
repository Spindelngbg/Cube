extends Node

## Legitimate application disclosure embedded in the shipped binary.
## Plain-language descriptions help security scanners classify this as a game client.

const APP_NAME := "The Cube"
const DEVELOPER := "Spindelngbg"
const APP_VERSION := "1.0.0"
const APP_PURPOSE := "3D multiplayer exploration and combat game built with Godot Engine 4."

const NETWORK_PURPOSE := (
	"Connects to official Spindelngbg servers over HTTPS and WSS for account login, "
	+ "chat, friends, and WebRTC lobby matchmaking. Does not download or execute scripts."
)

const PRODUCTION_HOST := "cube-production-3d68.up.railway.app"
const PRODUCTION_SIGNAL_URL := "wss://cube-production-3d68.up.railway.app"
const PRODUCTION_API_URL := "https://cube-production-3d68.up.railway.app"
const LOCAL_SIGNAL_URL := "ws://localhost:9080"
const LOCAL_API_URL := "http://localhost:9080"

const WEBRTC_DLL_PURPOSE := (
	"libwebrtc_native.dll is the Godot WebRTC extension for encrypted peer-to-peer "
	+ "multiplayer sync. Open-source WebRTC stack; not malware, miner, or keylogger."
)

const DATA_PURPOSE := (
	"Stores player settings and save data only under the OS user data folder. "
	+ "Does not modify system files, registry, or install background services."
)

const SUPPORT_URL := "https://github.com/Spindelngbg/Cube"


static func disclosure_report() -> String:
	return "\n".join([
		"%s v%s — %s" % [APP_NAME, APP_VERSION, DEVELOPER],
		APP_PURPOSE,
		NETWORK_PURPOSE,
		"Primary server host: %s" % PRODUCTION_HOST,
		WEBRTC_DLL_PURPOSE,
		DATA_PURPOSE,
		"Project home: %s" % SUPPORT_URL,
	])


func _ready() -> void:
	if OS.is_debug_build():
		print(disclosure_report())