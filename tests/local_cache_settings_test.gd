extends SceneTree


func _init() -> void:
    call_deferred("_run")


func _run() -> void:
    var cache: Node = root.get_node("LocalCache")
    if not cache.session_restore_done:
        await cache.session_restore_finished

    var path: String = cache.DATABASE_PATH
    var had_cache: bool = FileAccess.file_exists(path)
    var backup: PackedByteArray = FileAccess.get_file_as_bytes(path) if had_cache else PackedByteArray()
    var success: bool = true

    var file: FileAccess = FileAccess.open_encrypted_with_pass(path, FileAccess.WRITE, cache.PASSPHRASE)
    if file == null:
        push_error("Could not create LocalCache test fixture: %s" % error_string(FileAccess.get_open_error()))
        success = false
    else:
        file.store_string(JSON.stringify({
            "settings": {
                "music_volume": 0.35,
                "locale": "de"
            },
            "remembered_login": {
                "email": "legacy@example.com",
                "password": "must-not-be-used"
            }
        }))
        file.close()
        cache._load_cache()

        if cache.get_setting("music_volume", 1.0) != 0.35 or cache.get_setting("locale", "") != "de":
            push_error("LocalCache did not preserve device settings while removing legacy credentials")
            success = false

        file = FileAccess.open_encrypted_with_pass(path, FileAccess.READ, cache.PASSPHRASE)
        if file == null:
            push_error("Could not read LocalCache test result: %s" % error_string(FileAccess.get_open_error()))
            success = false
        else:
            var parsed: Variant = JSON.parse_string(file.get_as_text())
            file.close()
            if typeof(parsed) != TYPE_DICTIONARY or parsed.has("remembered_login"):
                push_error("LocalCache persisted legacy remembered credentials")
                success = false

    if had_cache:
        file = FileAccess.open(path, FileAccess.WRITE)
        if file == null:
            push_error("Could not restore LocalCache after test: %s" % error_string(FileAccess.get_open_error()))
            success = false
        else:
            file.store_buffer(backup)
            file.close()
    elif FileAccess.file_exists(path):
        var remove_error: Error = DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
        if remove_error != OK:
            push_error("Could not remove LocalCache test file: %s" % error_string(remove_error))
            success = false

    if success:
        print("LocalCache settings integration passed.")
        quit()
    else:
        quit(1)
