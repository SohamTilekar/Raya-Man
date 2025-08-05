extends RichTextLabel

var is_open: bool = false

func _ready() -> void:
	hide()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_console"):
		if is_open:
			hide()
			is_open = false
		else:
			show()
			is_open = true
