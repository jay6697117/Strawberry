extends GutTest

func test_save_migrates_to_current_schema() -> void:
    if not FileAccess.file_exists("res://scripts/save/save_migrator.gd"):
        fail_test("res://scripts/save/save_migrator.gd should exist")
        return

    var migrator_script := load("res://scripts/save/save_migrator.gd")
    assert_not_null(migrator_script)
    if migrator_script == null:
        return

    var raw := {"schema_version": 0, "gold": 500}
    var migrated = migrator_script.migrate(raw)

    assert_eq(migrated["schema_version"], migrator_script.CURRENT_SCHEMA)
    assert_true(migrated.has("season"))

func test_save_system_normalizes_fixture_data() -> void:
    if not FileAccess.file_exists("res://scripts/autoload/save_system.gd"):
        fail_test("res://scripts/autoload/save_system.gd should exist")
        return
    if not FileAccess.file_exists("res://test/fixtures/save_v0.json"):
        fail_test("res://test/fixtures/save_v0.json should exist")
        return

    var save_system_script := load("res://scripts/autoload/save_system.gd")
    assert_not_null(save_system_script)
    if save_system_script == null:
        return

    var file := FileAccess.open("res://test/fixtures/save_v0.json", FileAccess.READ)
    assert_not_null(file)
    if file == null:
        return

    var parsed = JSON.parse_string(file.get_as_text())
    assert_true(typeof(parsed) == TYPE_DICTIONARY)
    if typeof(parsed) != TYPE_DICTIONARY:
        return

    var save_system: Node = add_child_autofree(save_system_script.new())
    if not save_system.has_method("normalize_save_data"):
        fail_test("save_system.gd should expose normalize_save_data")
        return
    var normalized = save_system.normalize_save_data(parsed)
    assert_eq(normalized["schema_version"], 1)
    assert_eq(normalized["day"], 1)
