extends Panel

var inventory_panel
## All slot IDs are now strings. Integer indices will be converted to strings (e.g., "0", "1").
@export var index: String = ""

@onready var item_visual: Sprite2D = $Item

var slot_data: InvSlot

func _ready() -> void:
	item_visual.hide()

func update(new_slot_data: InvSlot) -> void:
	self.slot_data = new_slot_data
	if !slot_data or !slot_data.item:
		if item_visual.texture:
			item_visual.texture = null # Clears the texture
		item_visual.hide()
		
	else:
		item_visual.texture = slot_data.item.texture
		item_visual.show()

func _get_drag_data(_at_position: Vector2) -> Variant:
	if !slot_data or !slot_data.item:
		return null

	var drag_preview_node = TextureRect.new()
	drag_preview_node.texture = item_visual.texture
	drag_preview_node.size = self.size
	set_drag_preview(drag_preview_node)

	var payload = {
		"source_index": index,
		"data": slot_data
	}
	return payload

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	var can_drop = data is Dictionary and data.has("source_index")
	return can_drop

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if inventory_panel:
		var target_info = {
			"target_index": index,
			"data": slot_data
		}
		inventory_panel.handle_item_swap(data, target_info)
	else:
		printerr("inventory_panel is not set for slot ", index)
