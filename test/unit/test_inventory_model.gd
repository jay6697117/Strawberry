extends GutTest

func test_inventory_stacks_same_item() -> void:
    if not FileAccess.file_exists("res://scripts/inventory/inventory_model.gd"):
        fail_test("res://scripts/inventory/inventory_model.gd should exist")
        return

    var inventory_script := load("res://scripts/inventory/inventory_model.gd")
    assert_not_null(inventory_script)
    if inventory_script == null:
        return

    var inv = inventory_script.new(36)
    inv.add_item("parsnip", 5)
    inv.add_item("parsnip", 7)
    assert_eq(inv.get_total("parsnip"), 12)
