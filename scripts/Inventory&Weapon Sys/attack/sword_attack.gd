class_name SwordAttack extends Attack

var is_attacking: bool = false
var is_combo: bool = false
var wating_for_combo: bool = false
var attack_timer: float = 0.0
var combo_timer: float = 0.0
var return_timer: float = 0.0
var attack_rotation_start: float = 0.0
var attack_rotation_end: float = 0.0
var attack_angle_start: float = 0.0
var attack_angle_end: float = 0.0

func should_animate() -> bool:
	return is_attacking or wating_for_combo

func can_attack() -> bool:
	return !is_attacking

func can_attack_after() -> float:
	if is_attacking:
		return max(0.0, weapon.attack_duration - attack_timer)
	else:
		return max(0.0, weapon.return_duration - return_timer)

func update_weapon_pos(target: Vector2) -> void:
	if !should_animate():
		_set_weapon_sprite_pos(target)

func attack(target: Vector2) -> void:
	if wating_for_combo:
		_start_attack_reverse()
	if not is_attacking:
		_set_weapon_sprite_pos(target)
		_start_attack(target)

func handle_attack_animation(delta: float, target: Vector2) -> void:
	if weapon is Weapon and weapon.attack_types.has(Weapon.AttackType.Sword):
		if wating_for_combo:
			combo_timer += delta
			var ct = combo_timer / weapon.combo_lifespan
			if ct > 1.0:
				return_timer += delta
				var rt = return_timer / weapon.return_duration
				if rt > 1.0:
					return_timer = 0.0
					combo_timer = 0.0
					wating_for_combo = false
					_set_weapon_sprite_pos(target)
				else:
					var dir = (target - usr_sprite.global_position).normalized()
					weapon_sprite.rotation = Utils.lerp_angle_longest(attack_rotation_end + PI/6 if usr_sprite.flip_h else attack_rotation_end - PI/6, _get_weapon_rot(dir), rt)
					weapon_sprite.global_position = usr_sprite.global_position + \
						Vector2.from_angle(Utils.lerp_angle_longest(attack_angle_end + PI/6 if usr_sprite.flip_h else attack_angle_end - PI/6, _get_weapon_pos_dir(dir).angle(), rt)) * weapon.attack_radius
			else:
				weapon_sprite.rotation = lerp(attack_rotation_end, attack_rotation_end + PI/6 if usr_sprite.flip_h else attack_rotation_end - PI/6, ct)
				weapon_sprite.global_position = usr_sprite.global_position + Vector2.from_angle(lerp(attack_angle_end, attack_angle_end + PI/6 if usr_sprite.flip_h else attack_angle_end - PI/6, ct)) * weapon.attack_radius
			return
		if not is_attacking:
			return

		attack_timer += delta
		var at = attack_timer / weapon.attack_duration

		if at <= 1.0:
			# Ease-out interpolation: slows down as it approaches 1.0
			var eased_t = at * (2 - at)  # You can try pow(t, 0.8) as well for a softer ease

			# Animate sword swing by interpolating rotation and position
			weapon_sprite.rotation = Utils.lerp_angle_longest(attack_rotation_start, attack_rotation_end, eased_t)
			weapon_sprite.global_position = usr_sprite.global_position + \
				Vector2.from_angle(Utils.lerp_angle_longest(attack_angle_start, attack_angle_end, eased_t)) * weapon.attack_radius
			for effect in weapon.attack_effect_atlass:
				if at > effect.start_at:
					effect_sprite.flip_v = !is_combo if usr_sprite.flip_h else is_combo
					effect_sprite.texture.region = effect.region
					effect_sprite.offset = effect.offset
		else:
			is_attacking = false
			attack_timer = 0.0
			if is_combo:
				is_combo = false
			else:
				wating_for_combo = true
			effect_sprite.texture.region = Rect2(-1, -1, 1, 1)
			effect_sprite.hide()

func _start_attack(target: Vector2):
	var dir = (target - usr_sprite.global_position).angle()
	attack_rotation_start = weapon_sprite.rotation
	attack_rotation_end = attack_rotation_start + PI / 2 if usr_sprite.flip_h else attack_rotation_start - PI / 2
	attack_angle_end = attack_angle_start + PI / 2 if usr_sprite.flip_h else attack_angle_start - PI / 2
	effect_sprite.rotation = dir
	is_attacking = true
	effect_sprite.show()

func _start_attack_reverse():
	var temp = attack_rotation_end
	attack_rotation_end = attack_rotation_start
	attack_rotation_start = temp
	temp = attack_angle_end
	attack_angle_end = attack_angle_start
	attack_angle_start = temp

	is_attacking = true
	is_combo = true
	combo_timer = 0.0
	wating_for_combo = false
	effect_sprite.show()

func _get_weapon_rot(dir: Vector2) -> float:
	return PI + dir.angle() + PI / 4 if usr_sprite.flip_h else dir.angle() - PI / 4

func _get_weapon_pos_dir(dir: Vector2) -> Vector2:
	return dir.rotated(3 * PI / 4 if usr_sprite.flip_h else -3 * PI / 4).normalized()

func _set_weapon_sprite_pos(target: Vector2):
	var dir = (target - usr_sprite.global_position).normalized()
	var offset_dir = _get_weapon_pos_dir(dir)

	attack_angle_start = offset_dir.angle()

	# Offset sword rotation slightly forward
	weapon_sprite.rotation = _get_weapon_rot(dir)
	weapon_sprite.global_position = usr_sprite.global_position + offset_dir * weapon.attack_radius
