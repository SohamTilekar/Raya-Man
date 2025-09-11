extends CanvasLayer

@export var GameNode: Node2D

func _ready() -> void:
	self.hide()
	self.set_process_input(false)
	self.set_process_mode(Node.PROCESS_MODE_DISABLED)
	if not GameNode:
		printerr("GameNode Export var not set")

func _get_configuration_warnings() -> PackedStringArray:
	return [] if GameNode else ["GameNode Not Set"]

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_return_to_game_pressed()

func _on_exit_world_pressed() -> void:
	get_tree().root.add_child.call_deferred(load("res://scenes/UI/Main.tscn").instantiate())
	get_tree().root.remove_child(GameNode)

func _on_quit_game_pressed() -> void:
	get_tree().quit()

func _on_return_to_game_pressed() -> void:
	self.hide()
	self.set_process_mode(Node.PROCESS_MODE_DISABLED)
	self.set_process_input(false)
	GameNode.set_process_mode(Node.PROCESS_MODE_INHERIT)
	GameNode.set_process_input(true)
