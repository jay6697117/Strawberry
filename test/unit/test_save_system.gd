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
    var migrator_script := load("res://scripts/save/save_migrator.gd")
    assert_not_null(migrator_script)
    if migrator_script == null:
        return

    assert_eq(normalized["schema_version"], migrator_script.CURRENT_SCHEMA)
    assert_eq(normalized["day"], 1)
    assert_true(typeof(normalized.get("inventory", {})) == TYPE_DICTIONARY)
    assert_true(typeof(normalized.get("farm_plots", [])) == TYPE_ARRAY)

func test_apply_to_session_restores_inventory_and_farm_plots() -> void:
    if not FileAccess.file_exists("res://scripts/autoload/save_system.gd"):
        fail_test("res://scripts/autoload/save_system.gd should exist")
        return

    var save_system_script := load("res://scripts/autoload/save_system.gd")
    assert_not_null(save_system_script)
    if save_system_script == null:
        return

    if SessionState.inventory.has_method("replace_with_item_totals"):
        SessionState.inventory.replace_with_item_totals({})
    SessionState.farm_plots = []

    var save_system: Node = add_child_autofree(save_system_script.new())
    save_system.apply_to_session({
        "gold": 610,
        "day": 3,
        "season": "spring",
        "inventory": {"parsnip_seed": 4, "parsnip": 2},
        "farm_plots": [{
            "x": 2,
            "y": 5,
            "plot": {"soil_state": "wet", "crop_id": "parsnip", "stage": 1, "watered": true}
        }]
    })

    assert_eq(SessionState.gold, 610)
    assert_eq(SessionState.day, 3)
    assert_eq(SessionState.inventory.get_total("parsnip_seed"), 4)
    assert_eq(SessionState.inventory.get_total("parsnip"), 2)
    assert_eq(SessionState.farm_plots.size(), 1)
