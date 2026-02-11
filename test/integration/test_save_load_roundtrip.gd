extends GutTest

var _save_system_script = load("res://scripts/autoload/save_system.gd")

func before_each():
    # Reset SessionState before each test to ensure isolation
    SessionState.gold = 0
    SessionState.day = 1
    SessionState.season = "spring"
    SessionState.farm_plots = []
    if SessionState.inventory.has_method("replace_with_item_totals"):
        SessionState.inventory.replace_with_item_totals({})

func test_save_load_roundtrip_preserves_state() -> void:
    if _save_system_script == null:
        fail_test("Save system script not found")
        return

    var save_system = add_child_autofree(_save_system_script.new())

    # 1. Setup specific state
    SessionState.gold = 1234
    SessionState.day = 5
    SessionState.season = "summer"
    SessionState.inventory.add_item("parsnip_seed", 10)
    SessionState.inventory.add_item("hoe", 1)
    
    var plot_data = {
        "x": 2, 
        "y": 3, 
        "plot": {"soil_state": "wet", "crop_id": "parsnip", "stage": 2, "watered": true}
    }
    SessionState.farm_plots = [plot_data]

    # 2. Serialize (Save Logic)
    var saved_data = save_system.build_default_save_data()

    # 3. Reset SessionState (Simulate Quit)
    SessionState.gold = 0
    SessionState.day = 1
    SessionState.season = "spring"
    SessionState.farm_plots = []
    SessionState.inventory.replace_with_item_totals({})

    # 4. Deserialize (Load Logic)
    save_system.apply_to_session(saved_data)

    # 5. Verify
    assert_eq(SessionState.gold, 1234, "Gold should be restored")
    assert_eq(SessionState.day, 5, "Day should be restored")
    assert_eq(SessionState.season, "summer", "Season should be restored")
    assert_eq(SessionState.inventory.get_total("parsnip_seed"), 10, "Inventory (seeds) should be restored")
    assert_eq(SessionState.inventory.get_total("hoe"), 1, "Inventory (tools) should be restored")
    
    assert_eq(SessionState.farm_plots.size(), 1, "Farm plots count should be restored")
    if SessionState.farm_plots.size() > 0:
        var restored_plot = SessionState.farm_plots[0]
        assert_eq(restored_plot["x"], 2)
        assert_eq(restored_plot["y"], 3)
        var p = restored_plot["plot"]
        assert_eq(p["soil_state"], "wet")
        assert_eq(p["crop_id"], "parsnip")
        assert_eq(p["stage"], 2)
        assert_eq(bool(p["watered"]), true)

func test_gameplay_loop_state_is_saveable() -> void:
    # This test simulates the state AFTER a gameplay loop (end of day) 
    # and verifies it can be saved/loaded correctly.
    if _save_system_script == null:
        return

    var save_system = add_child_autofree(_save_system_script.new())

    # Simulate End of Day State
    # Day increments, gold changes, crops grow (state change)
    SessionState.day += 1
    SessionState.gold += 500 # Shipping bin earnings
    
    # Simulate crop growth
    var grown_plot = {
        "x": 0, "y": 0,
        "plot": {"soil_state": "dry", "crop_id": "parsnip", "stage": 1, "watered": false}
    }
    SessionState.farm_plots = [grown_plot]

    # Serialize
    var saved_data = save_system.build_default_save_data()
    
    # Verify the serialized data structure immediately (Schema Check)
    assert_true(saved_data.has("day"))
    assert_true(saved_data.has("gold"))
    assert_true(saved_data.has("farm_plots"))
    assert_eq(saved_data["day"], 2)
    
    # Reset
    SessionState.day = 1
    SessionState.farm_plots = []

    # Restore
    save_system.apply_to_session(saved_data)

    # Verify Logic
    assert_eq(SessionState.day, 2, "Day should be advanced after load")
    assert_eq(SessionState.gold, 500, "Gold should be updated after load")
    assert_eq(SessionState.farm_plots.size(), 1)
