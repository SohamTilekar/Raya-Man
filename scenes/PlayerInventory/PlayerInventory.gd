# player_inv.gd
class_name PlayerInv extends CanvasLayer

signal hand_node_update(item: Item)

var is_open: bool = false
var slot_scene = preload("res://scenes/PlayerInventory/InventorySlot.tscn")
var inv: Inv

@onready var grid_container: GridContainer = $GridContainer
@onready var hand_slot_node: Panel = $FastInv/Hand
@onready var fast_inv: HBoxContainer = $FastInv/FastInv

func _ready() -> void:
	close()

func init_inventory(inventory_resource: Inv) -> void:
	self.inv = inventory_resource
	if not inv.items:
		inv.items = []
	# Ensure special_items are initialized with InvSlot instances if they are null
	if not inv.special_items.has("hand") or not inv.special_items["hand"]:
		inv.special_items["hand"] = InvSlot.new()

	update_inventory_display()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("Inventory"):
		if is_open: close()
		else: open()

func open() -> void:
	is_open = true
	grid_container.show()
	$"Background Darkner".show()
	update_inventory_display()

func close() -> void:
	is_open = false
	grid_container.hide()
	$"Background Darkner".hide()

func _clear_children(container: Control) -> void:
	for child in container.get_children():
		child.queue_free()

func update_inventory_display() -> void:
	if not inv: return

	_clear_children(grid_container)
	_clear_children(fast_inv)
	
	for i in range(inv.items.size()):
		var slot_data = inv.items[i]
		var slot_node = slot_scene.instantiate()
		grid_container.add_child(slot_node)
		
		slot_node.inventory_panel = self
		slot_node.index = str(i) 
		slot_node.update(slot_data)
	
	hand_slot_node.inventory_panel = self
	hand_slot_node.index = "hand"
	var new_hand_slot_data = inv.special_items.get("hand")
	if hand_slot_node != new_hand_slot_data:
		if new_hand_slot_data:
			if new_hand_slot_data.item:
				hand_node_update.emit(new_hand_slot_data.item)
			else:
				hand_node_update.emit(null)
		else:
			hand_node_update.emit(null)
	hand_slot_node.update(new_hand_slot_data) 
	for slot in inv.special_items.keys():
		if slot.begins_with("fast_inv:"):
			var slot_data = inv.special_items[slot]
			var slot_node = slot_scene.instantiate()
			fast_inv.add_child(slot_node)
			slot_node.inventory_panel = self
			slot_node.index = slot
			slot_node.update(slot_data)

## Universal swap function to handle all drag-drop cases using string indices.
func handle_item_swap(source_info: Dictionary, target_info: Dictionary) -> void:
	if not inv: 
		printerr("Inventory resource is not initialized in player_inv.")
		return
	
	var source_index_str: String = source_info.source_index
	var target_index_str: String = target_info.target_index
	
	var source_data: InvSlot = source_info.data 
	var target_data: InvSlot = target_info.data 

	var set_slot_data = func(idx_str: String, data: InvSlot):
		if idx_str.is_valid_int():
			var idx_int: int = idx_str.to_int()
			if idx_int >= 0 and idx_int < inv.items.size():
				inv.items[idx_int] = data
			else:
				printerr("Grid index out of bounds (from string): ", idx_str)
		else: 
			if inv.special_items.has(idx_str):
				inv.special_items[idx_str] = data
			else:
				printerr("Special item key not found: ", idx_str)

	set_slot_data.call(source_index_str, target_data)
	set_slot_data.call(target_index_str, source_data)
	
	update_inventory_display()
