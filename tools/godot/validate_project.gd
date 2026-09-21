extends SceneTree

func _init() -> void:
    var required := [
        "res://project.godot",
        "res://main.tscn",
        "res://scripts/main.gd",
        "res://scripts/ecological_elements.gd",
        "res://scripts/blender_asset_loader.gd"
    ]

    var failures: Array[String] = []

    for path in required:
        if not FileAccess.file_exists(path):
            failures.append("Missing: " + path)

    var scene_resource := load("res://main.tscn")
    if scene_resource == null:
        failures.append("Could not load res://main.tscn")

    if failures.is_empty():
        print("SAVIA VALIDATION OK")
        quit(0)
    else:
        print("SAVIA VALIDATION FAILED")
        for failure in failures:
            print(" - " + failure)
        quit(1)
