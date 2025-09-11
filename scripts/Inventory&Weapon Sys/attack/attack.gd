class_name Attack extends RefCounted
enum AttackType {
	Sword
}
enum MovementType {
	None,
	Sword_Sorrund_target
}

@export var attack_condition: AttackCondition = null
@export var cooldown_range: Vector2 = Vector2(NAN, NAN)
@export var movement: MovementType = MovementType.Sword_Sorrund_target
@export var defence_dist_min: float = NAN
@export var defence_dist_max: float = NAN

func get_attack_condition() -> AttackCondition:
	return attack_condition

func set_attack_condion(_attack_condition: AttackCondition):
	self.attack_condition = _attack_condition

func can_attack() -> bool:
	return false

func can_attack_after() -> float:
	return INF

#region Weapon
var weapon: Weapon = null

func set_weapon(new_weapon: Weapon):
	self.weapon = new_weapon
	attack_condition = new_weapon.attack_condition
	cooldown_range = new_weapon.cooldown_range
	movement = new_weapon.movement
	defence_dist_min = new_weapon.defence_dist_min
	defence_dist_max = new_weapon.defence_dist_max

func get_weapon() -> Weapon:
	return weapon
#endregion

#region Usr
var usr_sprite: Node2D = null

func set_user_sprite(user: Node2D):
	usr_sprite = user

func get_user_sprite() -> Node2D:
	return usr_sprite
#endregion

#region WeaponSprite
var weapon_sprite: Node2D = null

func set_weapon_asprite(new_weapon_sprite: AnimatedSprite2D):
	self.weapon_sprite = new_weapon_sprite

func set_weapon_sprite(new_weapon_sprite: Sprite2D):
	self.weapon_sprite = new_weapon_sprite

func get_weapon_sprite() -> Node2D:
	return weapon_sprite
#endregion

#region Effect
var effect_sprite: Sprite2D = null

func set_effect_sprite(new_effect_sprite: Sprite2D):
	self.effect_sprite = new_effect_sprite

func get_effect_sprite() -> Node2D:
	return effect_sprite
#endregion

func should_animate() -> bool:
	return true

func update_weapon_pos(_target: Vector2) -> void:
	pass

func attack(_target: Vector2) -> void:
	pass

func handle_attack_animation(_delta: float, _target: Vector2) -> void:
	pass
