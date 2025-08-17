class_name HumanoidEntity
extends BaseEntity

#region SIGNALS
## Emitted when a new target is acquired
signal target_acquired(target)
## Emitted when the current target is lost
signal target_lost()
#endregion

#region CONFIGURATION

@export_category("Movement Speeds")
## Speed while wandering
@export_range(0.0, 200.0, 0.1, "or_greater") var walk_speed: float = 25.0
## Speed while chasing target
@export_range(0.0, 200.0, 0.1, "or_greater") var chase_speed: float = 45.0
## Speed boost after losing sight
@export_range(0.0, 200.0, 0.1, "or_greater") var burst_speed: float = 55.0
## Duration for which burst speed is applied
@export_range(0.0, 10.0, 0.1, "or_greater") var burst_time: float = 2.5
## Speed during search state
@export_range(0.0, 200.0, 0.1, "or_greater") var search_speed: float = 20.0

@export_category("Distances & Sensing")
## Maximum allowed wandering distance from spawn point
@export_range(0.0, 2000.0, 1.0, "or_greater") var max_wander_distance: float = 400.0
## Vision detection distance
@export_range(0.0, 2000.0, 1.0, "or_greater") var vision_distance: float = 200.0
## Close-range sensing distance
@export_range(0.0, 200.0, 0.1, "or_greater") var sense_distance: float = 32.0
## Width of vision cone (in degrees)
@export_range(0.0, 360.0, 0.1) var view_cone_deg: float = 160.0: set = _set_view_cone_deg
## Number of rays for vision cone scanning
@export_range(1, 256, 1) var view_ray_count: int = 32
## Number of rays for close-range sensing
@export_range(1, 256, 1) var sense_ray_count: int = 24

@export_category("Avoidance Tuning")
## Exponent applied to openness for avoidance calculation
@export_exp_easing var avoidance_exp_pow := 2
## Strength multiplier for avoidance force
@export_range(0.0, 10.0, 0.01, "or_greater") var avoidance_exp_strength := 0.8
## Smoothing factor for avoidance steering
@export var avoidance_smoothing_speed: float = 8

@export_category("Search Behaviour")
## Minimum search time after losing target
@export_range(0.0, 60.0, 0.1, "or_greater") var min_search_time: float = 6.0
## Number of search sectors
@export_range(1, 32, 1) var search_sector_count: int = 6
## Time spent facing a single search sector
@export_range(0.0, 10.0, 0.1, "or_greater") var search_hold_duration: float = 0.6

@export_category("Noise")
## Frequency of random noise for wandering movement
@export_range(0.0, 5.0, 0.001, "or_greater") var noise_frequency: float = 0.05

@export_category("Debugging")
## Whether to draw vision cones and debug visuals
@export var debug_draw_vision: bool = true

@export_category("Stuck Detection")
## Time before position is considered stuck
@export_range(0.0, 10.0, 0.01, "or_greater") var position_stuck_time: float = 0.3
## Time before area is considered stuck
@export_range(0.0, 60.0, 0.1, "or_greater") var area_stuck_time: float = 4.0
## Distance threshold for position stuck detection
@export_range(0.0, 50.0, 0.01, "or_greater") var position_stuck_distance: float = 1.0
## Threshold for reaching a target area
@export_range(0.0, 200.0, 0.1, "or_greater") var area_reach_threshold: float = 32.0

#endregion


#region CONSTANTS_DERIVED
## Vision cone in radians (updated via setter)
var VIEW_CONE_ANGLE := deg_to_rad(view_cone_deg)
const TAU_F := TAU
#endregion


#region STATE_AND_DATA

## Entity AI states
enum State { WANDER, CHASE, SEARCH }

## Combat/chase enums
enum CombatMode { HUNT, OFFENSE }
enum ChaseMode { DEFENSE, STRIKE }

## Current AI state
var state: State = State.WANDER:
	set = _set_state

#region Target tracking
## Current node being chased (if any)
var chase_target: CharacterBody2D = null
## Last known position of chase target
var last_known_position: Vector2 = Vector2.ZERO
## Last known velocity of chase target
var last_known_velocity: Vector2 = Vector2.ZERO
#endregion

#region Movement / timers
var speed_current: float = 0.0
var burst_timer: float = 0.0
var lost_sight_timer: float = 0.0
var travel_time_to_last_known: float = 0.0
#endregion

#region Stuck detection variables
var _last_pos: Vector2 = Vector2.ZERO
var _position_stuck_timer: float = 0.0
var _area_stuck_timer: float = 0.0
var _stuck_state_failures: int = 0
var _last_target_pos: Vector2 = Vector2.ZERO
#endregion

#region Wandering
var _cord: float = 0.0
#endregion

#region Search state
var search_timer: float = 0.0
var search_sector_index: int = 0
var _search_target_dir: Vector2 = Vector2.ZERO
var _search_hold_timer: float = 0.0
#endregion

#region Avoidance / smoothing buffers
var _avoidance_vector_smoothed: Vector2 = Vector2.ZERO
var _min_openness := 1.0

class SampleInfo:
	var dir: Vector2
	var hit_pos: Vector2
	var openness: float
	func _init(n_dir: Vector2, n_openness: float, n_hit_pos: Vector2):
		dir = n_dir
		openness = n_openness
		hit_pos = n_hit_pos

var _sample_info: Array[SampleInfo] = []
var _points: PackedVector2Array = []
var _last_ray_points: PackedVector4Array = []
var _last_ray_hit_points: PackedVector2Array = []
#endregion

#region Movement base
var move_direction: Vector2 = Vector2.RIGHT
var spawn_point: Vector2 = Vector2.ZERO
#endregion

#endregion


#region NODE_REFERENCES
@onready var sprite_node: AnimatedSprite2D = $Humanoid
@onready var item_sprite: Sprite2D = $Item
@onready var effect_node: Node2D = $Effect
@onready var attack_sys: AttackSys = AttackSys.new()
@export var nav_agent: NavigationAgent2D = NavigationAgent2D.new()

#region Exported resources
@export var type_name: String
@export var sprite_frames: SpriteFrames
@export var visual_offset: Vector2 = Vector2.ZERO
@export var in_hand_item: Item
@export var noise: FastNoiseLite = FastNoiseLite.new()
#endregion
#endregion


#region READY_AND_INIT
## Called when the node is ready
func _ready() -> void:
	nav_agent.target_desired_distance = area_reach_threshold
	_init_attack_sys()
	_init_visuals()
	_init_noise()
	spawn_point = global_position
	speed_current = walk_speed
	_last_pos = global_position

## Setup visuals and sprite
func _init_visuals() -> void:
	if sprite_frames:
		sprite_node.sprite_frames = sprite_frames
	if visual_offset:
		sprite_node.offset = visual_offset
	sprite_node.play("run")
	set_in_hand_item(in_hand_item)

## Setup attack system references
func _init_attack_sys() -> void:
	attack_sys.set_user_sprite(sprite_node)
	attack_sys.set_weapon_sprite(item_sprite)
	attack_sys.set_effect_sprite(effect_node)

## Initialize noise generator for wandering
func _init_noise() -> void:
	noise.seed = randi()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.fractal_type = FastNoiseLite.FRACTAL_NONE
	noise.frequency = noise_frequency
#endregion


#region PROCESS
func _process(_delta: float) -> void:
	queue_redraw()

func _physics_process(delta: float) -> void:
	_clear_ray_buffers()
	update_vision(delta)

	match state:
		State.WANDER: _behave_wander(delta)
		State.CHASE: _behave_chase(delta)
		State.SEARCH: _behave_search(delta)

	_move_and_apply_velocity(delta)
	_check_stuck(delta)

## Apply movement to the entity
func _move_and_apply_velocity(_delta: float) -> void:
	move_and_slide()
	turn_entity(move_direction.normalized().x)
#endregion


#region STATE_BEHAVIOURS

## Wander: produce a noisy wander + bias towards spawn_point
func _behave_wander(delta: float) -> void:
	_cord += delta
	var wander_dir = _noise_dir(_cord)
	var to_home = spawn_point - global_position
	var dist = to_home.length()
	var home_weight = pow(dist / max_wander_distance, 2)

	move_direction = calculate_avoidance_vec([
		DirectionWeight.new(wander_dir, 1.0),
		DirectionWeight.new(to_home, home_weight)
	], delta)

	velocity = move_direction * walk_speed
	speed_current = walk_speed

#region Chase Mode
# Combat state variables
var combat_mode: CombatMode = CombatMode.HUNT
var chase_mode: ChaseMode = ChaseMode.DEFENSE

var defense_timer := 0.0
var strike_cooldown := 0.0
var selected_attack: Attack = null
var selected_attack_name: String = ""

## Chase behaviour: split logic for readability
func _behave_chase(delta: float) -> void:
	_cord += delta
	burst_timer = _decay_timer(burst_timer, delta)
	strike_cooldown = _decay_timer(strike_cooldown, delta)

	if chase_target and is_instance_valid(chase_target):
		_update_chase_with_target(delta)
	else:
		_update_chase_without_target(delta)

	velocity = move_direction * speed_current

func _update_chase_with_target(delta: float) -> void:
	var target_pos = chase_target.global_position
	attack_sys.handle_attack_animation(delta, target_pos)
	var to_target = target_pos - global_position
	var distance = to_target.length()
	last_known_position = target_pos

	_select_best_attack_from_available()
	_update_combat_mode(distance)

	if selected_attack == null or combat_mode == CombatMode.HUNT:
		_handle_hunt(delta, to_target)
		return

	_handle_offense(delta, to_target, distance, target_pos)

func _select_best_attack_from_available() -> void:
	selected_attack = null
	selected_attack_name = ""
	var available_attacks: Dictionary[String, Attack] = attack_sys.get_available_attacks()
	var max_range := -1.0
	for aname in available_attacks:
		var attack: Attack = available_attacks[aname]
		# preserve your existing movement type filter
		if attack.movement == Attack.MovementType.Sword_Sorrund_target:
			if attack.attack_condition.max_dist_frm_target > max_range:
				max_range = attack.attack_condition.max_dist_frm_target
				selected_attack_name = aname
				selected_attack = attack

func _update_combat_mode(distance: float) -> void:
	if not selected_attack:
		combat_mode = CombatMode.HUNT
		return
	if distance > 1.3 * selected_attack.defence_dist_max:
		if combat_mode != CombatMode.HUNT:
			print("HUNT")
		combat_mode = CombatMode.HUNT
	else:
		if combat_mode != CombatMode.OFFENSE:
			print("OFFENSE")
		combat_mode = CombatMode.OFFENSE

func _update_chase_without_target(delta: float) -> void:
	# LOST TARGET behavior
	lost_sight_timer += delta

	var to_last = last_known_position - global_position
	var reach_thresh = delta * velocity.length() * 2 if _min_openness == 1.0 else sense_distance

	if to_last.length() < reach_thresh:
		travel_time_to_last_known = max(lost_sight_timer * 2.0, min_search_time)
		_start_search()
		return

	# move toward last known position with avoidance
	move_direction = calculate_avoidance_vec([DirectionWeight.new(to_last.normalized(), 1.0)], delta)
	# optionally apply burst speed if recently lost sight
	speed_current = burst_speed if burst_timer > 0.0 else chase_speed

func _start_search() -> void:
	search_timer = 0.0
	search_sector_index = 0
	_set_state(State.SEARCH)

func _handle_hunt(delta: float, to_target: Vector2) -> void:
	var dist_factor = clamp(global_position.distance_to(last_known_position) / vision_distance * 1.5, 0.0, 1.0)
	var noise_weight = lerp(0.0, 0.4, dist_factor)
	move_direction = calculate_avoidance_vec([
		DirectionWeight.new(to_target.normalized(), 1.0),
		DirectionWeight.new(_noise_dir(_cord), noise_weight)
	], delta)
	speed_current = chase_speed

func _handle_offense(delta: float, to_target: Vector2, distance: float, target_pos: Vector2) -> void:
	match chase_mode:
		ChaseMode.DEFENSE:
			_handle_defense_mode(delta, to_target, distance)
		ChaseMode.STRIKE:
			_handle_strike_mode(delta, to_target, distance, target_pos)

func _handle_defense_mode(delta: float, to_target: Vector2, distance: float) -> void:
	defense_timer += delta
	speed_current = walk_speed

	var def_min = selected_attack.defence_dist_min
	var def_max = selected_attack.defence_dist_max

	# Fallback if values are invalid
	if is_nan(def_min): def_min = 40.0
	if is_nan(def_max): def_max = 80.0

	# Movement logic
	var distance_weight := remap(distance, def_min, def_max, 0, 1)
	move_direction = calculate_avoidance_vec([
		DirectionWeight.new(-to_target, 1.0 - distance_weight), # Avoid when close
		DirectionWeight.new(to_target, distance_weight),        # Attract when far
		#DirectionWeight.new(to_target, 1, 1),                   # Make it Revolve
		DirectionWeight.new(_noise_dir(_cord), 1.0),            # Always apply noise
	], delta)
	if distance_weight < 0:
		speed_current = walk_speed * clampf(distance_weight * -1 + 1, 1, 2)
	elif distance_weight > 1:
		speed_current = walk_speed * clampf(distance_weight, 1, 2)

	# Cooldown logic using range from attack (random only once)
	if not has_meta("defense_duration_threshold"):
		var min_cd = selected_attack.cooldown_range.x
		var max_cd = selected_attack.cooldown_range.y
		if is_nan(min_cd) or is_nan(max_cd):
			min_cd = 2.0
			max_cd = 4.0
		set_meta("defense_duration_threshold", randf_range(min_cd, max_cd))

	var duration_threshold = get_meta("defense_duration_threshold")

	if defense_timer >= duration_threshold:
		chase_mode = ChaseMode.STRIKE
		defense_timer = 0.0
		remove_meta("defense_duration_threshold")

func _handle_strike_mode(delta: float, to_target: Vector2, distance: float, target_pos: Vector2) -> void:
	move_direction = calculate_avoidance_vec([
		DirectionWeight.new(to_target.normalized(), 1.0)
	], delta)
	speed_current = chase_speed

	var mid_range = (selected_attack.attack_condition.min_dist_frm_target + selected_attack.attack_condition.max_dist_frm_target) / 2.0
	var tolerance = 0.2 * (selected_attack.attack_condition.max_dist_frm_target - selected_attack.attack_condition.min_dist_frm_target)
	var strike_band_min = mid_range - tolerance
	var strike_band_max = mid_range + tolerance

	if distance >= strike_band_min and distance <= strike_band_max:
		print("Attacked")
		attack_sys.trigger_attack(selected_attack_name, target_pos)
		strike_cooldown = 2.0
		chase_mode = ChaseMode.DEFENSE
		defense_timer = 0.0
#endregion

## Search behaviour: lighter logic, shorter functions
func _behave_search(delta: float) -> void:
	search_timer += delta
	_search_hold_timer += delta
	_cord += delta / 2

	var expand_factor = clamp(search_timer / max(travel_time_to_last_known, 0.0001), 0.0, 1.0)
	var sector_angle = TAU_F / max(search_sector_count, 1)
	var bias_strength = lerp(1.0, 0.2, expand_factor)
	var base_facing = last_known_velocity.angle() if not last_known_velocity.is_zero_approx() else move_direction.angle()

	if _search_hold_timer >= search_hold_duration:
		_generate_new_search_dir(base_facing, sector_angle, bias_strength)
	_search_steer_and_move(delta)

	# exit search after we've spent the allotted travel time
	if search_timer >= travel_time_to_last_known:
		_set_state(State.WANDER)

func _generate_new_search_dir(base_facing: float, sector_angle: float, bias_strength: float) -> void:
	_search_hold_timer = 0.0
	var target_angle = base_facing + (search_sector_index * sector_angle)
	var base_dir = Vector2.RIGHT.rotated(target_angle)

	if not last_known_velocity.is_zero_approx():
		base_dir = (base_dir * (1.0 - bias_strength) + last_known_velocity.normalized() * bias_strength).normalized()
		var noise_dir = _noise_dir(_cord)
		_search_target_dir = (base_dir * 0.6 + noise_dir * 0.4).normalized()
	else:
		_search_target_dir = _noise_dir(_cord)

	# if immediate ray hits an obstacle, nudge laterally
	if _is_direction_blocked(base_dir, sense_distance * 0.6):
		var lateral = (last_known_velocity.rotated(PI / 2) if not last_known_velocity.is_zero_approx() else base_dir.rotated(PI / 2)).normalized()
		if randi() % 2 == 0:
			lateral = -lateral
		_search_target_dir = (_search_target_dir + lateral * 0.4).normalized()

	search_sector_index = (search_sector_index + 1) % search_sector_count

func _search_steer_and_move(delta: float) -> void:
	move_direction = move_direction.slerp(_search_target_dir, 5.0 * delta)
	move_direction = calculate_avoidance_vec([DirectionWeight.new(move_direction, 1.0)], delta)
	speed_current = search_speed
	velocity = move_direction * speed_current
#endregion


#region VISION_AND_SENSING
var _ray_rotation_offset := 0.0 # store rotation between frames

func update_vision(delta: float) -> void:
	_sample_info.clear()
	_min_openness = 1.0
	_ray_rotation_offset += (TAU_F / sense_ray_count) * delta
	_ray_rotation_offset = wrapf(_ray_rotation_offset, 0.0, TAU_F)

	# 1) peripheral sense
	var found_target := _scan_peripheral_sense()

	# 2) quick LOS refresh for existing chase target
	if _quick_refresh_chase_target():
		return
	if combat_mode == CombatMode.OFFENSE:
		return

	# 3) forward cone
	if found_target == null:
		found_target = _scan_forward_cone()

	# 4) handle state transitions
	if found_target != null and found_target != chase_target:
		_on_target_acquired(found_target)
	elif found_target == null and chase_target != null:
		_on_target_lost()

func _scan_peripheral_sense() -> Node2D:
	var eye_pos = global_position
	var found_target: Node2D = null
	for i in range(sense_ray_count):
		var angle = TAU_F * i / sense_ray_count + _ray_rotation_offset
		var dir: Vector2 = Vector2.from_angle(angle)
		var exclude: Array = []
		if self.chase_target:
			exclude.append(self.chase_target)
		var hit: Dictionary = _raycast(eye_pos, eye_pos + dir * sense_distance, exclude)
		var openness := 1.0
		var hit_pos: Vector2 = Vector2.ZERO
		if hit:
			hit_pos = hit.position
			var dist = eye_pos.distance_to(hit_pos)
			openness = clamp(dist / sense_distance, 0.0, 1.0)
		_sample_info.append(SampleInfo.new(dir, openness, hit_pos))
		_min_openness = min(_min_openness, openness)
		if hit and is_instance_valid(hit.collider) and _is_valid_target(hit.collider):
			found_target = hit.collider
	return found_target

func _quick_refresh_chase_target() -> bool:
	if chase_target and is_instance_valid(chase_target) and global_position.distance_to(chase_target.global_position) <= vision_distance * 1.5:
		if _has_line_of_sight(global_position, chase_target.global_position, chase_target):
			last_known_velocity = chase_target.velocity
			last_known_position = chase_target.global_position
			return true
	return false

func _scan_forward_cone() -> Node2D:
	var eye_pos = global_position
	var facing_angle = move_direction.angle()
	for i in range(view_ray_count):
		var angle = -VIEW_CONE_ANGLE/2.0 + (VIEW_CONE_ANGLE * i / float(max(view_ray_count - 1, 1)))
		var dir = Vector2.RIGHT.rotated(facing_angle + angle)
		var hit = _raycast(eye_pos, eye_pos + dir * vision_distance)
		if hit and is_instance_valid(hit.collider) and _is_valid_target(hit.collider):
			return hit.collider
	return null

func _on_target_acquired(found_target: Node2D) -> void:
	chase_target = found_target
	last_known_position = found_target.global_position
	last_known_velocity = found_target.velocity
	lost_sight_timer = 0.0
	burst_timer = 0.0
	target_acquired.emit(chase_target)
	_set_state(State.CHASE)

func _on_target_lost() -> void:
	chase_target = null
	burst_timer = burst_time
	lost_sight_timer = 0.0
	target_lost.emit()

func _raycast(from_pos: Vector2, to_pos: Vector2, exclude: Array = []) -> Dictionary:
	var params = PhysicsRayQueryParameters2D.create(from_pos, to_pos)
	params.exclude = [self] + exclude
	_last_ray_points.append(Vector4(from_pos.x, from_pos.y, to_pos.x, to_pos.y))
	var ret := get_world_2d().direct_space_state.intersect_ray(params)
	if ret.is_empty():
		_last_ray_hit_points.append(Vector2.ZERO)
	else:
		_last_ray_hit_points.append(ret.position)
	return ret

func _has_line_of_sight(from_pos: Vector2, to_pos: Vector2, target: Node) -> bool:
	var res = _raycast(from_pos, to_pos)
	return res.size() > 0 and res.collider == target

func _is_direction_blocked(dir: Vector2, length: float) -> bool:
	var hit = _raycast(global_position, global_position + dir.normalized() * length)
	return hit.size() > 0

func _clear_ray_buffers() -> void:
	_last_ray_points.clear()
	_last_ray_hit_points.clear()
#endregion


#region AVOIDANCE_AND_STUCK

class DirectionWeight extends RefCounted:
	var direction: Vector2
	var weight: float
	var angle_dif: float

	func _init(dir: Vector2, w: float, n_angle_dif: float = 0.0):
		direction = dir.normalized()
		weight = w
		angle_dif = n_angle_dif

## Calculate combined avoidance + goal steering
func calculate_avoidance_vec(inputs: Array[DirectionWeight], delta: float) -> Vector2:
	# Separate contributions to make behavior easier to tune:
	#  - obstacle avoidance (from hits)
	#  - directional influence (from inputs)
	var avoidance_vec := Vector2.ZERO
	var directional_vec := Vector2.ZERO

	# obstacle responses
	for info in _sample_info:
		if not info.hit_pos.is_zero_approx():
			var hit_dir := (info.hit_pos - global_position).normalized()
			# push away inversely proportional to openness
			avoidance_vec += hit_dir * -avoidance_exp_strength / pow(max(info.openness, 0.001), avoidance_exp_pow)
		else:
			# accumulate directional alignment/revolve influence
			for input in inputs:
				if input is DirectionWeight:
					var palign := input.direction.dot(info.dir.rotated(input.angle_dif))
					var nalign := input.direction.dot(info.dir.rotated(-input.angle_dif))
					directional_vec += info.dir * palign * input.weight
					directional_vec += info.dir * nalign * input.weight

	# smooth historical vector
	avoidance_vec += _avoidance_vector_smoothed * (avoidance_smoothing_speed * delta * 1000)
	var combined := (directional_vec + avoidance_vec)

	# normalize and store smoothed result for next frame
	if combined.is_zero_approx():
		_avoidance_vector_smoothed = Vector2.ZERO
	else:
		_avoidance_vector_smoothed = combined.normalized()

	return _avoidance_vector_smoothed

func _check_stuck(delta: float) -> void:
	# POSITION stuck detection (short)
	if global_position.distance_to(_last_pos) <= position_stuck_distance:
		_position_stuck_timer += delta
	else:
		_position_stuck_timer = 0.0
		_last_pos = global_position

	if _position_stuck_timer >= position_stuck_time:
		print("⚠ Position stuck detected in state: ", state)
		_handle_stuck("position")
		_position_stuck_timer = 0.0

	# AREA stuck detection (longer)
	_perform_area_stuck_check(delta)

func _perform_area_stuck_check(delta: float) -> void:
	var target_pos = Vector2.ZERO
	var doing_area_check = false

	if state == State.CHASE:
		target_pos = last_known_position
		doing_area_check = true
	elif state == State.SEARCH:
		# SEARCH-specific quick fallback
		if _position_stuck_timer >= position_stuck_time * 1.5:
			print("⚠ SEARCH stuck detected → Pathfinding to home")
			_try_pathfinding_to(spawn_point)
			_handle_stuck("area")
		return
	elif state == State.WANDER:
		return

	# Reset timer if target changed
	if _last_target_pos != target_pos:
		_area_stuck_timer = 0.0
		_last_target_pos = target_pos

	# Check movement direction relevance
	var moving_toward_target := false
	if not move_direction.is_zero_approx():
		var to_target = (target_pos - global_position).normalized()
		moving_toward_target = move_direction.dot(to_target) > 0.3  # ~60° cone

	# Check if there are obstacles in sense rays
	var obstacle_detected := false
	for info in _sample_info:
		if info.hit_pos != Vector2.ZERO:
			obstacle_detected = true
			break

	# Increment timer only if we’re not moving toward target and there is an obstacle
	if doing_area_check and not moving_toward_target and obstacle_detected:
		if global_position.distance_to(target_pos) > area_reach_threshold:
			_area_stuck_timer += delta
		else:
			_area_stuck_timer = 0.0
	else:
		_area_stuck_timer = 0.0

	# Handle area stuck
	if _area_stuck_timer >= area_stuck_time:
		print("⚠ Area stuck detected in state: ", state)
		_try_pathfinding_to(target_pos)
		_handle_stuck("area")
		_area_stuck_timer = 0.0

func _handle_stuck(_stuck_type: String) -> void:
	# small state-machine for stuck recovery
	if state == State.CHASE:
		_stuck_state_failures = 0
		_set_state(State.SEARCH)
	elif state == State.SEARCH:
		_stuck_state_failures += 1
		if _stuck_state_failures >= 2:
			_stuck_state_failures = 0
			_set_state(State.WANDER)
		else:
			_set_state(State.SEARCH)

func _try_pathfinding_to(target_pos: Vector2) -> void:
	if not nav_agent:
		return
	nav_agent.target_position = target_pos
	if nav_agent.is_navigation_finished():
		return
	var next_path_point = nav_agent.get_next_path_position()
	if next_path_point != Vector2.ZERO:
		move_direction = (next_path_point - global_position).normalized()
		print("📍 Pathfinding to target:", target_pos)
#endregion


#region UTILITY
func _noise_dir(t: float) -> Vector2:
	return Vector2.from_angle(remap(noise.get_noise_1d(t), -1.0, 1.0, 0.0, TAU_F)).normalized()

func _set_view_cone_deg(v: float) -> void:
	view_cone_deg = v
	VIEW_CONE_ANGLE = deg_to_rad(view_cone_deg)

func _set_state(new_state: State) -> void:
	if state == new_state:
		return
	state = new_state
	match state:
		State.WANDER:
			print("WANDER")
			chase_target = null
			last_known_position = Vector2.ZERO
			last_known_velocity = Vector2.ZERO
			speed_current = walk_speed
		State.CHASE:
			print("CHASE")
			speed_current = chase_speed
		State.SEARCH:
			print("SEARCH")
			search_timer = 0.0
			_search_hold_timer = 0.0

func _is_valid_target(body: Node) -> bool:
	if body == null:
		return false
	if body.has_method("is_humanoid") and body.is_humanoid():
		return true
	if body.name == "Player":
		return true
	return false

func _decay_timer(value: float, rate: float) -> float:
	return max(0.0, value - rate)

func _increment_timer(value: float, rate: float) -> float:
	return max(0.0, value + rate)
#endregion


func _draw() -> void:
	if not debug_draw_vision:
		return

	# forward cone
	var facing_angle = move_direction.angle()
	var cone_radius = vision_distance
	var cone_points: PackedVector2Array = [Vector2.ZERO]
	for i in range(view_ray_count):
		var angle = -VIEW_CONE_ANGLE / 2.0 + (VIEW_CONE_ANGLE * i / float(max(view_ray_count - 1, 1)))
		cone_points.append(Vector2.RIGHT.rotated(facing_angle + angle) * cone_radius)
	draw_colored_polygon(cone_points, Color(0, 0.8, 0.8, 0.08))

	# draw samples from avoidance
	for i in range(_last_ray_hit_points.size()):
		var from_to := _last_ray_points[i]
		var hit := _last_ray_hit_points[i]

		var start := Vector2(from_to.x, from_to.y) - global_position
		var end := Vector2(from_to.z, from_to.w) - global_position

		if hit:
			var hit_pos := hit - global_position
			draw_circle(hit_pos, 3, Color(1, 0.2, 0.2, 0.9))
			end = hit_pos  # shorten line to hit point

		draw_line(start, end, Color(1, 0.2, 0.2, 0.9), 1.2)

	for point in _points:
		draw_circle(point - global_position, area_reach_threshold, Color.MAGENTA)

	draw_circle(self.spawn_point - global_position, 3, Color.BLACK)
	draw_circle(self.spawn_point - global_position, max_wander_distance, Color.GOLD, false, 3, true)

	# avoidance vector
	if not _avoidance_vector_smoothed.is_zero_approx():
		draw_line(Vector2.ZERO, _avoidance_vector_smoothed * (sense_distance + 8.0), Color(0.1, 1, 0.3), 3.0)

	# basic direction
	if not move_direction.is_zero_approx():
		draw_line(Vector2.ZERO, move_direction.normalized() * 20.0, Color(0, 1, 1), 2.0)

	if chase_target and selected_attack:
		draw_circle(chase_target.global_position - global_position, selected_attack.attack_condition.min_dist_frm_target, Color.RED, false, 0.3, true)
		draw_circle(chase_target.global_position - global_position, selected_attack.attack_condition.max_dist_frm_target, Color.BLUE, false, 0.3, true)
		draw_circle(chase_target.global_position - global_position, selected_attack.defence_dist_min, Color.ORANGE_RED, false, 0.3, true)
		draw_circle(chase_target.global_position - global_position, selected_attack.defence_dist_max, Color.BLUE_VIOLET, false, 0.3, true)

	draw_circle(last_known_position - global_position, 3, Color.YELLOW)


#region ITEM_HANDLING
## Sets the currently held item
func set_in_hand_item(item: Item) -> void:
	in_hand_item = item
	if item and item.can_hold_in_hand:
		item_sprite.texture = item.inhand_texture if item.inhand_texture else item.texture
		item_sprite.offset = item.hand_hold_offset
		item_sprite.visible = true
		if item is Weapon:
			attack_sys.set_weapon(item, move_direction)
		else:
			attack_sys.set_weapon(null, move_direction)
	else:
		item_sprite.texture = null
		item_sprite.offset = Vector2.ZERO
		item_sprite.visible = false
		attack_sys.set_weapon(null, move_direction)

## Returns the currently held item
func get_in_hand_item() -> Item:
	return in_hand_item
#endregion


#region CONFIG_WARNINGS
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := []
	if not sprite_frames:
		warnings.append("Entity Sprite Frames Not Set")
	var names: PackedStringArray = sprite_frames.get_animation_names() if sprite_frames else PackedStringArray()
	for anim in ["run", "idle", "hurt", "spawn", "death"]:
		if not names.has(anim):
			warnings.append("`%s` animation not set in the Entity Sprite Frames." % anim)
	return warnings
#endregion


#region FLIP
## Flip sprite horizontally based on direction
func turn_entity(dir: float) -> void:
	# Prefer last_known_position when chasing for correct facing
	if last_known_position and state == State.CHASE:
		if last_known_position.x < (self.global_position.x - 10):
			sprite_node.flip_h = true
			attack_sys.update_weapon_pos(last_known_position)
		elif last_known_position.x > (self.global_position.x + 10):
			sprite_node.flip_h = false
			attack_sys.update_weapon_pos(last_known_position)
		return

	# Default flipping based on movement direction
	if dir < 0.49:
		sprite_node.flip_h = true
		attack_sys.update_weapon_pos(self.global_position + move_direction)
	elif dir > 0.51:
		sprite_node.flip_h = false
		attack_sys.update_weapon_pos(self.global_position + move_direction)
#endregion
