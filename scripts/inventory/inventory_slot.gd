extends RefCounted
class_name InventorySlot

var item_id: String = ""
var amount: int = 0

func is_empty() -> bool:
    return item_id.is_empty() or amount <= 0
