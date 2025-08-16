class_name AttackCondition extends Resource

@export var input_action: String = ""
@export var precidence: float = 0.

@export var min_dist_frm_target: float = 0.
@export var max_dist_frm_target: float = INF
enum MovementType {
	None,
	Sword_Sorrund_target
}
@export var movement: MovementType = MovementType.Sword_Sorrund_target

func condition_matches(event: InputEvent, _mouse_position_relative: Vector2) -> bool:
	if input_action != "":
		return event.is_action_pressed(input_action)
	return false
