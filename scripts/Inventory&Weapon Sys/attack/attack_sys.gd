class_name AttackSys extends RefCounted

# Dictionary to hold all registered attacks
var attacks: Dictionary[String, Attack] = {}

#region Weapon
var weapon: Weapon = null

func set_weapon(new_weapon: Weapon, target: Vector2):
	if weapon:
		for type in weapon.attack_types:
			match type:
				Attack.AttackType.Sword:
					unregister_attack("sword")
		if weapon.attack_effect_texture:
			effect_sprite.texture = null

	weapon = new_weapon

	if weapon:
		for type in weapon.attack_types:
			match type:
				Attack.AttackType.Sword:
					var sword_attack := SwordAttack.new()
					register_attack("sword", sword_attack)
		if weapon.attack_effect_texture:
			effect_sprite.texture = AtlasTexture.new()
			effect_sprite.texture.atlas = weapon.attack_effect_texture
	update_weapon_pos(target)

func get_weapon() -> Weapon:
	return weapon
#endregion

#region User
var usr_sprite: Node2D = null

func set_user_sprite(user: Node2D):
	usr_sprite = user
	for attack in attacks.values():
		attack.set_user(user)

func get_user_sprite() -> Node2D:
	return usr_sprite
#endregion

#region WeaponSprite
var weapon_sprite: Node2D = null

func set_weapon_asprite(sprite: AnimatedSprite2D):
	self.weapon_sprite = sprite
	for attack in attacks.values():
		attack.set_weapon_asprite(sprite)

func set_weapon_sprite(sprite: Sprite2D):
	self.weapon_sprite = sprite
	for attack in attacks.values():
		attack.set_weapon_sprite(sprite)

func get_weapon_sprite() -> Node2D:
	return weapon_sprite
#endregion

#region Effect
var effect_sprite: Sprite2D = null

func set_effect_sprite(new_effect_sprite: Sprite2D):
	self.effect_sprite = new_effect_sprite
	for attack in attacks.values():
		attack.set_effect_sprite(new_effect_sprite)

func get_effect_sprite() -> Node2D:
	return effect_sprite
#endregion

# Register a new attack under a unique name
func register_attack(name: String, attack: Attack) -> void:
	attacks[name] = attack
	attack.set_user_sprite(usr_sprite)
	attack.set_weapon(weapon)
	attack.set_effect_sprite(effect_sprite)
	if weapon_sprite is AnimatedSprite2D:
		attack.set_weapon_asprite(weapon_sprite)
	elif weapon_sprite is Sprite2D:
		attack.set_weapon_sprite(weapon_sprite)

# Unregister an existing attack
func unregister_attack(name: String) -> void:
	attacks.erase(name)

# Return Array of currently available attacks
func get_available_attacks() -> Dictionary[String, Attack]:
	var available: Dictionary[String, Attack] = {}
	for name in attacks:
		var attack = attacks[name]
		if attack.can_attack():
			available[name] = attack
	return available

# Trigger a specific attack if possible
func trigger_attack(name: String, target: Vector2) -> void:
	if not attacks.has(name):
		push_warning("Attack '%s' not registered." % name)
		return

	var attack: Attack = attacks[name]
	if attack.can_attack():
		attack.attack(target)

func get_best_attack(_user: Vector2, _target: Vector2, _has_los: bool, _vel: Vector2) -> String:
	return ""

# Update weapon position for specific attack types
func update_weapon_pos(target: Vector2) -> void:
	for attack in attacks.values():
		if attack.has_method("update_weapon_pos"):
			attack.update_weapon_pos(target)

# Handle animations only for those attacks that require it
func handle_attack_animation(delta: float, target: Vector2) -> void:
	for attack in attacks.values():
		if attack.should_animate():
			attack.handle_attack_animation(delta, target)
