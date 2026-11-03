extends SceneTree


func _init() -> void:
    call_deferred("_run")


func _run() -> void:
    var service: GDScript = load("res://autoload/live_update_service.gd")
    var success: bool = true

    var old_map: Dictionary = {"a": {"id": "a"}, "b": {"id": "b"}}
    var same: Dictionary = service.diff_notifications(old_map, old_map.duplicate())
    success = _check(same.added.is_empty() and same.removed.is_empty(), "identical snapshots produce no diff") and success

    var new_map: Dictionary = {"b": {"id": "b"}, "c": {"id": "c"}}
    var diff: Dictionary = service.diff_notifications(old_map, new_map)
    success = _check(diff.added.size() == 1 and diff.added[0].id == "c", "added notification detected") and success
    success = _check(diff.removed == ["a"], "removed notification detected") and success

    var from_empty: Dictionary = service.diff_notifications({}, new_map)
    success = _check(from_empty.added.size() == 2 and from_empty.removed.is_empty(), "everything is added from an empty snapshot") and success

    quit(0 if success else 1)


func _check(condition: bool, label: String) -> bool:
    if not condition:
        push_error("FAILED: %s" % label)
    return condition
