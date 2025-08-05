class_name Attack extends RefCounted

var attack_condition: AttackCondition = null

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

func set_weapon(weapon: Weapon):
	self.weapon = weapon
	attack_condition = weapon.attack_condition

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

func set_weapon_asprite(weapon_sprite: AnimatedSprite2D):
	self.weapon_sprite = weapon_sprite

func set_weapon_sprite(weapon_sprite: Sprite2D):
	self.weapon_sprite = weapon_sprite

func get_weapon_sprite() -> Node2D:
	return weapon_sprite
#endregion

#region Effect
var effect_sprite: Sprite2D = null

func set_effect_sprite(effect_sprite: Sprite2D):
	self.effect_sprite = effect_sprite

func get_effect_sprite() -> Node2D:
	return effect_sprite
#endregion

func should_animate() -> bool:
	return true

#func update_weapon_pos() -> void:
	#pass

func attack(dir: Vector2 = Vector2.ZERO) -> void:
	pass

func handle_attack_animation(delta: float) -> void:
	pass
