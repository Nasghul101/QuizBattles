## @meta-authors Kyle Szklenski
## @meta-version 2.6
## The Firebase Godot API.
## This singleton gives you access to your Firebase project and its capabilities. Using this requires you to fill out some Firebase configuration settings. It currently comes with four modules.
## 	- [code]Auth[/code]: Manages user authentication (logging and out, etc...)
## 	- [code]Database[/code]: A NonSQL realtime database for managing data in JSON structures.
## 	- [code]Firestore[/code]: Similar to Database, but stores data in collections and documents, among other things.
## 	- [code]Storage[/code]: Gives access to Cloud Storage; perfect for storing files like images and other assets.
## 	- [code]RemoteConfig[/code]: Gives access to Remote Config functionality; allows you to download your app's configuration from Firebase, do A/B testing, and more.
##
## @tutorial https://github.com/GodotNuts/GodotFirebase/wiki
@tool
extends Node

const _ENVIRONMENT_VARIABLES : String = "firebase/environment_variables"
const _EMULATORS_PORTS : String = "firebase/emulators/ports"
const _AUTH_PROVIDERS : String = "firebase/auth_providers"
const _RUNTIME_MODE_SETTING : String = "firebase/runtime_mode"

## @type FirebaseAuth
## The Firebase Authentication API.
@onready var Auth := $Auth

## @type FirebaseFirestore
## The Firebase Firestore API.
@onready var Firestore := $Firestore

## @type FirebaseDatabase
## The Firebase Realtime Database API.
@onready var Database := $Database

## @type FirebaseStorage
## The Firebase Storage API.
@onready var Storage := $Storage

## @type FirebaseDynamicLinks
## The Firebase Dynamic Links API.
@onready var DynamicLinks := $DynamicLinks

## @type FirebaseFunctions
## The Firebase Cloud Functions API
@onready var Functions := $Functions

## @type FirebaseRemoteConfig
## The Firebase Remote Config API
@onready var RemoteConfigAPI := $RemoteConfig

@export var emulating : bool = true

var configuration_ready: bool = false
var configuration_error: String = ""
var emulator_host: String = "127.0.0.1"

# Configuration used by all files in this project
# These values can be found in your Firebase Project
# See the README checked Github for how to access
var _config : Dictionary = {
	"apiKey": "",
	"authDomain": "",
	"databaseURL": "",
	"projectId": "",
	"databaseName": "",
	"storageBucket": "",
	"messagingSenderId": "",
	"appId": "",
	"measurementId": "",
	"clientId": "",
	"clientSecret" : "",
	"domainUriPrefix" : "",
	"functionsGeoZone" : "",
	"cacheLocation":"",
	"emulators": {
		"ports" : {
			"authentication" : "",
			"firestore" : "",
			"realtimeDatabase" : "",
			"functions" : "",
			"storage" : "",
			"dynamicLinks" : ""
		}
	},
	"workarounds":{
		"database_connection_closed_issue": false, # fixes https://github.com/firebase/firebase-tools/issues/3329
	},
	"auth_providers": {
		"facebook_id":"",
		"facebook_secret":"",
		"github_id":"",
		"github_secret":"",
		"twitter_id":"",
		"twitter_secret":""
	}
}

func _ready() -> void:
	_load_config()


func set_emulated(emulating : bool = true) -> void:
	configuration_ready = false
	self.emulating = true
	_check_emulating()
	if emulating:
		if not _validate_emulator_configuration():
			return
	else:
		if OS.is_debug_build():
			_fail_configuration("Production Firebase mode is only allowed in a release build.")
			return
		if not _validate_production_configuration():
			return
		self.emulating = false
		_check_emulating()

	configuration_error = ""
	configuration_ready = true

func _check_emulating() -> void:
	if emulating:
		print("[Firebase] You are now in 'emulated' mode: the services you are using will try to connect to your local emulators, if available.")
	for module in get_children():
		if module.has_method("_check_emulating"):
			module._check_emulating()

func _load_config() -> void:
	var env = ConfigFile.new()
	var err = env.load("res://addons/godot-firebase/.env")
	if err != OK:
		_fail_configuration("Unable to read Firebase configuration at res://addons/godot-firebase/.env.")
		return

	var runtime_mode := str(ProjectSettings.get_setting(_RUNTIME_MODE_SETTING, "emulator"))
	for key in _config.keys():
		var config_value = _config[key]
		if key == "emulators" and config_value.has("ports"):
			for port in config_value.ports.keys():
				config_value.ports[port] = env.get_value(_EMULATORS_PORTS, port, "")
		elif key == "auth_providers":
			for provider in config_value.keys():
				config_value[provider] = env.get_value(_AUTH_PROVIDERS, provider, "")
		else:
			var value: String = env.get_value(_ENVIRONMENT_VARIABLES, key, "")
			if value == "" and key == "functionsGeoZone" and runtime_mode == "emulator":
				value = str(ProjectSettings.get_setting("firebase/functions_region", ""))
			if value == "":
				_print("The value for `%s` is not configured. If you are not planning to use it, ignore this message." % key)
			else:
				_config[key] = value

	if runtime_mode == "emulator":
		emulating = true
		_config.projectId = str(ProjectSettings.get_setting("firebase/emulator_project_id", "demo-quizbattles"))
		emulator_host = str(ProjectSettings.get_setting("firebase/emulator_host", "127.0.0.1")).strip_edges()
		var emulator_config: Dictionary = _config.get("emulators", {})
		var ports: Dictionary = emulator_config.get("ports", {})
		for service in ["authentication", "firestore", "functions"]:
			if str(ports.get(service, "")).strip_edges().is_empty():
				ports[service] = str(ProjectSettings.get_setting("firebase/emulators/ports/%s" % service, ""))
		if not _validate_emulator_configuration():
			return
	elif runtime_mode == "production":
		if OS.is_debug_build():
			_fail_configuration("Production Firebase mode is only allowed in a release build.")
			return
		if not _validate_production_configuration():
			return
		emulating = false
	else:
		_fail_configuration("Invalid Firebase runtime mode '%s'; expected 'emulator' or 'production'." % runtime_mode)
		return

	_setup_modules()
	configuration_error = ""
	configuration_ready = true


func _validate_emulator_configuration() -> bool:
	var project_id := str(_config.get("projectId", "")).strip_edges()
	if not project_id.begins_with("demo-"):
		_fail_configuration("Firebase emulator mode requires a demo project ID beginning with 'demo-'.")
		return false

	if emulator_host.is_empty() or emulator_host.contains("://") or emulator_host.contains("/") or emulator_host.contains("\\") or emulator_host.contains(":"):
		_fail_configuration("Firebase emulator host must be a hostname or IPv4 address without a scheme or port.")
		return false

	var emulator_config: Dictionary = _config.get("emulators", {})
	var ports: Dictionary = emulator_config.get("ports", {})
	for service in ["authentication", "firestore", "functions"]:
		var port_text := str(ports.get(service, "")).strip_edges()
		if not port_text.is_valid_int():
			_fail_configuration("Firebase emulator mode requires a valid %s port." % service)
			return false
		var port := int(port_text)
		if port < 1 or port > 65535:
			_fail_configuration("Firebase emulator mode requires a valid %s port." % service)
			return false

	if str(_config.get("functionsGeoZone", "")).strip_edges().is_empty():
		_fail_configuration("Firebase emulator mode requires a Functions region.")
		return false
	return true


func get_emulator_url(port: String, path: String) -> String:
	return "http://%s:%s/%s" % [emulator_host, port, path.trim_prefix("/")]


func _validate_production_configuration() -> bool:
	for key in ["apiKey", "authDomain", "projectId", "functionsGeoZone"]:
		if str(_config.get(key, "")).strip_edges().is_empty():
			_fail_configuration("Production Firebase mode requires the '%s' configuration value." % key)
			return false
	return true


func _fail_configuration(message: String) -> void:
	configuration_ready = false
	configuration_error = message
	_printerr(message)

func _setup_modules() -> void:
	for module in get_children():
		module._set_config(_config)
		if not module.has_method("_on_FirebaseAuth_login_succeeded"):
			continue
		Auth.login_succeeded.connect(module._on_FirebaseAuth_login_succeeded)
		Auth.signup_succeeded.connect(module._on_FirebaseAuth_login_succeeded)
		Auth.token_refresh_succeeded.connect(module._on_FirebaseAuth_token_refresh_succeeded)
		Auth.logged_out.connect(module._on_FirebaseAuth_logout)

# -------------

func _printerr(error : String) -> void:
	printerr("[Firebase Error] >> " + error)

func _print(msg : String) -> void:
	print("[Firebase] >> " + str(msg))
