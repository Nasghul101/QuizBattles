extends SceneTree

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if not _expect(root.has_node("Firebase"), "Firebase autoload is missing."):
		return

	var firebase = root.get_node("Firebase")
	if not _expect(firebase.configuration_ready, "Firebase emulator configuration did not initialize."):
		return
	if not _expect(firebase.emulating, "Development must use the Firebase emulators."):
		return
	if not _expect(firebase._config.projectId == "demo-quizbattles", "Emulator mode did not select the demo project."):
		return
	var auth = firebase.get_node("Auth")
	if not _expect(auth._base_url.begins_with("http://"), "Auth did not select a local endpoint."):
		return
	var desktop_host: String = firebase.emulator_host
	firebase.emulator_host = "10.0.2.2"
	firebase._check_emulating()
	if not _expect(auth._base_url.begins_with("http://10.0.2.2:9099/"), "The configured mobile host was not used."):
		return
	firebase.emulator_host = desktop_host
	firebase._check_emulating()

	var auth_port: String = firebase._config.emulators.ports.authentication
	firebase._config.emulators.ports.authentication = ""
	if not _expect(not firebase._validate_emulator_configuration(), "An empty Auth port was accepted."):
		return
	if not _expect(not firebase.configuration_ready, "Firebase stayed ready with a missing emulator port."):
		return
	if not _expect(firebase.emulating, "A missing emulator port disabled emulator mode."):
		return
	if not _expect(not auth._base_url.begins_with("https://"), "A missing emulator port selected production."):
		return

	firebase._config.emulators.ports.authentication = auth_port
	firebase.configuration_error = ""
	firebase.configuration_ready = true
	firebase._config.emulators.ports.authentication = "1"
	firebase._check_emulating()
	if not _expect(auth._base_url.begins_with("http://127.0.0.1:1/"), "An unavailable emulator selected a non-local endpoint."):
		return
	auth.login_with_email_and_password("emulator-unavailable@example.invalid", "invalid-test-password")
	var auth_result: Array = await auth.auth_request
	if not _expect(str(auth_result[0]) != "1", "An unavailable emulator unexpectedly accepted authentication."):
		return

	print("Firebase runtime mode checks passed.")
	quit()


func _expect(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false
