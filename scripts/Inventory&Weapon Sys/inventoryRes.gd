# Inv.gd
extends Resource
class_name Inv

# A single array to hold all inventory slot data.
@export var items: Array[InvSlot]

@export var special_items: Dictionary[String, InvSlot] = {}

@export var special_data: Dictionary = {}

## Saves the inventory resource to a file.
func save_inventory(path: String = "user://inventory.tres") -> void:
	ResourceSaver.save(self, path)

## Static function to load inventory.
static func load_inventory(path: String = "user://inventory.tres") -> Inv:
	if ResourceLoader.exists(path):
		var loaded_inv = ResourceLoader.load(path)
		if loaded_inv is Inv:
			return loaded_inv
	# If no save exists, create and return a fresh inventory.
	var new_inv = Inv.new()
	new_inv.items = []
	return new_inv
