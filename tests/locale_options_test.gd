extends SceneTree


func _init() -> void:
    call_deferred("_run")


func _run() -> void:
    var cache: Node = root.get_node("LocalCache")
    if not cache.session_restore_done:
        await cache.session_restore_finished

    var utils: Node = root.get_node("Utils")
    var trivia: Node = root.get_node("TriviaQuestionService")
    var original_locale: String = cache.get_setting("locale", "")
    var success: bool = true

    if utils._map_os_locale("zh_Hant_TW") != "zh_TW" or utils._map_os_locale("zh-HK") != "zh_TW":
        push_error("Traditional Chinese OS locales did not map to zh_TW")
        success = false
    if utils._map_os_locale("zh_CN") == "zh_TW" or utils._map_os_locale("de_DE") != "de":
        push_error("OS locale mapping is wrong for non-Traditional locales")
        success = false

    utils.set_app_locale("zh_TW")
    if cache.get_setting("locale", "") != "zh_TW" or TranslationServer.get_locale() != "zh_TW":
        push_error("set_app_locale did not apply and persist zh_TW")
        success = false
    if trivia._get_user_language() != "zt":
        push_error("zh_TW did not select questions_zt.json")
        success = false

    utils.set_app_locale("de")
    if trivia._get_user_language() != "de":
        push_error("de did not select questions_de.json")
        success = false

    utils.reset_app_locale()
    if cache.get_setting("locale", "x") != "" or TranslationServer.get_locale() != utils.resolve_locale():
        push_error("reset_app_locale did not clear the stored locale and re-resolve it")
        success = false

    cache.set_setting("locale", original_locale)

    if success:
        print("Locale options test passed.")
        quit()
    else:
        quit(1)
