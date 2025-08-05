class_name AttackCondition extends Resource

@export var input_action: String = ""
@export var precidence: int = 0

func condition_matches(event: InputEvent) -> bool:
	if input_action != "":
		return event.is_action_pressed(input_action)
	return false
