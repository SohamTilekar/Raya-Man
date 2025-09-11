extends CanvasLayer

func _on_start_game_pressed() -> void:
	get_tree().root.add_child.call_deferred(preload("res://scenes/GameWorld.tscn").instantiate())
	get_tree().root.remove_child(self)

func _on_quit_game_pressed() -> void:
	get_tree().quit()
