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
@export_range(0.0, 360.0, 0.1) var view_cone_deg: float = 160.0:
	set = _set_view_cone_deg

## Number of rays for vision cone scanning
@export_range(1, 256, 1) var view_ray_count: int = 32

## Number of rays for close-range sensing
@export_range(1, 256, 1) var sense_ray_count: int = 24



@export_category("Avoidance Tuning")

## Exponent applied to openness for avoidance calculation
@export_exp_easing var avoidance_exp_pow := 1.2

## Strength multiplier for avoidance force
@export_range(0.0, 10.0, 0.01, "or_greater") var avoidance_exp_strength := 4

## Weight for alignment in avoidance
@export_range(0.0, 1.0, 0.01) var avoidance_align_weight := 0.8

## Smoothing factor for avoidance steering
@export_range(0.0, 5.0, 0.01) var avoidance_smoothing_speed: float = 0.8



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
#endregion


#region STATE_AND_DATA

## Entity AI states
enum State { WANDER, CHASE, SEARCH }

## Current AI state
var state: State = State.WANDER:
	set = _set_state


#region Target tracking
## Current node being chased (if any)
var chase_target: Node2D = null

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
	_init_visuals()
	_init_attack_sys()
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
	_last_ray_points.clear()
	_last_ray_hit_points.clear()

	# Update perception first
	update_vision(delta)

	# Run state behaviour
	match state:
		State.WANDER: _behave_wander(delta)
		State.CHASE: _behave_chase(delta)
		State.SEARCH: _behave_search(delta)

	# Apply movement and check if stuck
	_move_and_apply_velocity(delta)
	_check_stuck(delta)

## Apply movement to the entity
func _move_and_apply_velocity(_delta: float) -> void:
	turn_entity(move_direction.normalized().x)
	move_and_slide()
#endregion


#region STATE_BEHAVIOURS
func _behave_wander(delta: float) -> void:
	_cord += delta
	# random wander direction with bias to spawn point
	var wander_dir = _noise_dir(_cord)
	var to_home = (spawn_point - global_position)
	var dist = to_home.length()
	var home_weight = pow(clamp(dist / max_wander_distance, 0.0, 1.0), 2)
	var wander_weight = 1.0 - home_weight

	move_direction = (wander_dir * wander_weight + to_home.normalized() * home_weight).normalized()
	move_direction = _get_avoidance_vector()
	velocity = move_direction * walk_speed
	attack_sys.handle_attack_animation(delta, global_position + velocity * delta)
	attack_sys.update_weapon_pos(global_position + velocity * delta)

func _behave_chase(delta: float) -> void:
	_cord += delta
	var target_vec = Vector2.ZERO

	if chase_target and is_instance_valid(chase_target):
		target_vec = (chase_target.global_position - global_position).normalized()
		last_known_position = chase_target.global_position
	else:
		lost_sight_timer += delta
		var to_last = last_known_position - global_position
		if to_last.length() < delta * velocity.length():
			travel_time_to_last_known = max(lost_sight_timer * 2.0, min_search_time)
			search_timer = 0.0
			search_sector_index = 0
			_set_state(State.SEARCH)
			return
		target_vec = to_last.normalized()

	var obstacles_nearby := false
	for info in _sample_info:
		if info.hit_pos:
			obstacles_nearby = true

	var noise_weight = 0.0
	var target_weight = 1.0
	if not obstacles_nearby:
		var dist_factor = clamp(global_position.distance_to(last_known_position) / vision_distance, 0.0, 1.0)
		noise_weight = lerp(0.0, 0.4, dist_factor)
		target_weight = 1.0 - noise_weight * (1.0 if chase_target and is_instance_valid(chase_target) else 0.0)
		var noise_dir = _noise_dir(_cord)
		move_direction = (target_vec * target_weight + noise_dir * noise_weight).normalized()
	else:
		move_direction = target_vec
	move_direction = _get_avoidance_vector()

	var desired_speed = chase_speed
	if burst_timer > 0.0:
		desired_speed = burst_speed
		burst_timer = max(0.0, burst_timer - delta)
	speed_current = lerp(speed_current, desired_speed, 5.0 * delta)
	velocity = move_direction * speed_current

func _behave_search(delta: float) -> void:
	search_timer += delta
	_search_hold_timer += delta
	_cord += delta / 2

	# expand search over time and pick sectors to look at
	var expand_factor = clamp(search_timer / max(travel_time_to_last_known, 0.0001), 0.0, 1.0)
	var sector_angle = TAU / max(search_sector_count, 1)
	var bias_strength = lerp(1.0, 0.2, expand_factor)
	var base_facing = last_known_velocity.angle() if !last_known_velocity.is_zero_approx() else move_direction.angle()

	if _search_hold_timer >= search_hold_duration:
		_search_hold_timer = 0.0
		var target_angle = base_facing + (search_sector_index * sector_angle)
		var base_dir = Vector2.RIGHT.rotated(target_angle)

		if not last_known_velocity.is_zero_approx():
			# normal blend when we have movement data
			base_dir = (base_dir * (1.0 - bias_strength) + last_known_velocity.normalized() * bias_strength).normalized()

			var noise_dir = _noise_dir(_cord)
			_search_target_dir = (base_dir * 0.6 + noise_dir * 0.4).normalized()
		else:
			# no movement data → rely entirely on noise
			_search_target_dir = _noise_dir(_cord)

		# if immediate ray hits an obstacle, slightly nudge the search direction laterally
		if _is_direction_blocked(base_dir, sense_distance * 0.6):
			var lateral = (last_known_velocity.rotated(PI / 2) if not last_known_velocity.is_zero_approx() else base_dir.rotated(PI / 2)).normalized()
			if randi() % 2 == 0:
				lateral = -lateral
			_search_target_dir = (_search_target_dir + lateral * 0.4).normalized()

		search_sector_index = (search_sector_index + 1) % search_sector_count

	# steer toward the search target dir and apply avoidance
	move_direction = move_direction.slerp(_search_target_dir, 5.0 * delta)
	move_direction = _get_avoidance_vector()
	speed_current = lerp(speed_current, search_speed, 4.0 * delta)
	velocity = move_direction * speed_current

	# exit search after we've spent the allotted travel time
	if search_timer >= travel_time_to_last_known:
		_set_state(State.WANDER)
#endregion


#region VISION_AND_SENSING
func update_vision(_delta: float) -> void:
	# scan cone + rear to find valid targets
	var eye_pos = global_position
	var found_target: Node2D = null
	var facing_angle = move_direction.angle()
	_sample_info.clear()
	_min_openness = 1.0

	# gather samples around the agent
	# rear / peripheral sense (shorter)
	for i in range(sense_ray_count):
		var angle = TAU * i / sense_ray_count
		var dir: Vector2 = Vector2.from_angle(angle)
		var hit: Dictionary = _raycast(eye_pos, eye_pos + dir * sense_distance)
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

	# quick LOS check for current chase target (helps avoid re-detecting through walls)
	if chase_target and is_instance_valid(chase_target) and eye_pos.distance_to(chase_target.global_position) <= vision_distance * 1.5:
		if _has_line_of_sight(eye_pos, chase_target.global_position, chase_target):
			last_known_velocity = chase_target.velocity
			last_known_position = chase_target.global_position
			return

	# forward cone
	for i in range(view_ray_count):
		var angle = -VIEW_CONE_ANGLE/2.0 + (VIEW_CONE_ANGLE * i / float(max(view_ray_count - 1, 1)))
		var dir = Vector2.RIGHT.rotated(facing_angle + angle)
		var hit = _raycast(eye_pos, eye_pos + dir * vision_distance)
		if hit and is_instance_valid(hit.collider) and _is_valid_target(hit.collider):
			found_target = hit.collider
			break


	# handle target state transitions
	if found_target != null and found_target != chase_target:
		# new target acquired
		chase_target = found_target
		last_known_position = found_target.global_position
		last_known_velocity = found_target.velocity
		lost_sight_timer = 0.0
		target_acquired.emit(chase_target)
		_set_state(State.CHASE)
	elif found_target == null and chase_target != null:
		# lost sight
		chase_target = null
		burst_timer = burst_time
		lost_sight_timer = 0.0
		target_lost.emit()

func _raycast(from_pos: Vector2, to_pos: Vector2) -> Dictionary:
	var params = PhysicsRayQueryParameters2D.create(from_pos, to_pos)
	params.exclude = [self]
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

#endregion


#region AVOIDANCE_AND_STUCK
func _get_avoidance_vector() -> Vector2:
	var desired_dir := move_direction.normalized() if !move_direction.is_zero_approx() else Vector2.RIGHT
	var global_proximity := 1.0 - _min_openness

	var sum_dir := Vector2.ZERO
	var sum_score := 0.0

	for info in _sample_info:
		if not info.hit_pos.is_zero_approx():
			continue
		var dir := info.dir
		var openness := info.openness

		var alignment := (dir.dot(desired_dir) + 1.0) / 2
		var base_score := alignment * avoidance_align_weight + openness * (1.0 - avoidance_align_weight)
		var exp_boost := 1.0 + pow(global_proximity, avoidance_exp_pow) * avoidance_exp_strength
		var score: float = max(base_score * exp_boost, 0.0)

		sum_dir += dir * score
		sum_score += score

	var new_avoidance_vector := desired_dir if sum_score <= 0.0 else (sum_dir / sum_score).normalized()
	var angle_diff: float = abs(_avoidance_vector_smoothed.angle_to(new_avoidance_vector))
	if angle_diff > deg_to_rad(90) or _min_openness < 0.3:
		# snap instantly if big turn or very close to an obstacle
		_avoidance_vector_smoothed = new_avoidance_vector
	else:
		# smooth normally
		_avoidance_vector_smoothed = _avoidance_vector_smoothed.slerp(
			new_avoidance_vector,
			clamp(avoidance_smoothing_speed * get_process_delta_time(), 0.0, 1.0)
		)
	#_avoidance_vector_smoothed = new_avoidance_vector

	return _avoidance_vector_smoothed

func _check_stuck(delta: float) -> void:
	# --- Position stuck check ---
	if global_position.distance_to(_last_pos) <= position_stuck_distance:
		_position_stuck_timer += delta
	else:
		_position_stuck_timer = 0.0
		_last_pos = global_position

	if _position_stuck_timer >= position_stuck_time:
		print("⚠ Position stuck detected in state: ", state)
		_handle_stuck("position")
		_position_stuck_timer = 0.0
	
	# --- Area stuck check ---
	var target_pos = Vector2.ZERO
	var doing_area_check = false

	if state == State.CHASE:
		target_pos = last_known_position
		doing_area_check = true
	elif state == State.SEARCH:
		# No specific target in SEARCH → check stuck and path to spawn if blocked
		if _position_stuck_timer >= position_stuck_time * 1.5:
			print("⚠ SEARCH stuck detected → Pathfinding to home")
			_try_pathfinding_to(spawn_point)
			_handle_stuck("area")
		return
	elif state == State.WANDER:
		return  # wander doesn’t need area check

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
		if info.hit_pos != Vector2.ZERO: # means ray collided
			obstacle_detected = true
			break

	# Increment timer only if we’re moving toward target AND there’s an obstacle
	if doing_area_check and moving_toward_target and obstacle_detected:
		if global_position.distance_to(target_pos) > area_reach_threshold:
			_area_stuck_timer += delta
		else:
			_area_stuck_timer = 0.0
	else:
		_area_stuck_timer = 0.0  # reset if not in a stuck-prone situation

	# Handle area stuck
	if _area_stuck_timer >= area_stuck_time:
		print("⚠ Area stuck detected in state: ", state)
		_try_pathfinding_to(target_pos)
		_handle_stuck("area")
		_area_stuck_timer = 0.0

func _handle_stuck(_stuck_type: String) -> void:
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

# --- _get_avoidance_vector, _check_stuck, _handle_stuck, _try_pathfinding_to ---
#endregion


#region UTILITY
func _noise_dir(t: float) -> Vector2:
	return Vector2.from_angle(remap(noise.get_noise_1d(t), -1.0, 1.0, 0.0, TAU)).normalized()

func _set_view_cone_deg(v: float) -> void:
	view_cone_deg = v
	# UPDATE constant-like value used elsewhere
	VIEW_CONE_ANGLE = deg_to_rad(view_cone_deg) if typeof(VIEW_CONE_ANGLE) == TYPE_NIL else deg_to_rad(view_cone_deg)

func _set_state(new_state: State) -> void:
	if state == new_state:
		return
	state = new_state
	match state:
		State.WANDER:
			# reset some tracking values
			chase_target = null
			last_known_position = Vector2.ZERO
			last_known_velocity = Vector2.ZERO
		State.CHASE:
			# start chase ramp
			speed_current = max(speed_current, chase_speed / 2)
		State.SEARCH:
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

	# avoidance vector
	if not _avoidance_vector_smoothed.is_zero_approx():
		draw_line(Vector2.ZERO, _avoidance_vector_smoothed * (sense_distance + 8.0), Color(0.1, 1, 0.3), 3.0)

	# basic direction
	if not move_direction.is_zero_approx():
		draw_line(Vector2.ZERO, move_direction.normalized() * 20.0, Color(0, 1, 1), 2.0)

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
	if dir < 0.49:
		sprite_node.flip_h = true
		effect_node.flip_h = true
	elif dir > 0.51:
		sprite_node.flip_h = false
		effect_node.flip_h = false
#endregion
