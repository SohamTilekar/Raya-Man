extends CharacterBody2D

# CONSTANTS & SIGNALS

const WALK_SPEED: float = 100.0
const RUN_SPEED: float = 150.0

signal player_moved_vel(vel: Vector2)
signal player_moved_pos(pos: Vector2)

# EXPORTS & NODES

@export var inventory: Inv = preload("res://resources/PlayerInventory.tres")

@onready var player_inventory: PlayerInv = $PlayerInventory
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var item_sprite: Sprite2D = $Item
@onready var effect_sprite: Sprite2D = $Effect
@onready var anim_tree_state_machine: AnimationNodeStateMachinePlayback = animation_tree["parameters/playback"]

# STATE VARIABLES

var last_vec: Vector2 = Vector2.ZERO
var in_hand_item: Item = null
var attack_sys: AttackSys = AttackSys.new()

# READY

func _ready() -> void:
	player_inventory.init_inventory(inventory)
	attack_sys.set_user_sprite($Character)
	attack_sys.set_weapon_sprite(item_sprite)
	attack_sys.set_effect_sprite(effect_sprite)

# INVENTORY HAND UPDATE

func _on_player_inventory_hand_node_update(item: Item):
	in_hand_item = item
	if item and item.can_hold_in_hand:
			item_sprite.texture = item.inhand_texture if item.inhand_texture else item.texture
			item_sprite.offset = item.hand_hold_offset
			item_sprite.show()
			if item is Weapon:
				attack_sys.set_weapon(item, get_global_mouse_position())
	else:
		item_sprite.texture = null
		item_sprite.offset = Vector2.ZERO
		item_sprite.hide()

# PHYSICS PROCESS

func _physics_process(delta: float) -> void:
	handle_movement(delta)
	attack_sys.handle_attack_animation(delta, get_global_mouse_position())

func _process(_delta: float) -> void:
	queue_redraw()

# MOVEMENT HANDLING

func handle_movement(delta: float) -> void:
	var is_running = Input.is_action_pressed("ctrl")
	var speed = RUN_SPEED if is_running else WALK_SPEED

	var input_direction = Vector2(
		Input.get_axis("char left", "char right"),
		Input.get_axis("char up", "char down")
	).normalized()

	# Velocity multiplier includes modifier keys
	velocity = input_direction * speed * delta * 100.0 \
		* (40.0 if Input.is_action_pressed("shift") else 1.0) \
		* (15.0 if Input.is_action_pressed("alt") else 1.0)


	if velocity != last_vec:
		animation_tree["parameters/run/RunSpeed/scale"] = 2. if is_running else 1.6
		anim_tree_state_machine.travel("run" if velocity != Vector2.ZERO else "idle")
		last_vec = velocity

	move_and_slide()

	if velocity != Vector2.ZERO:
		player_moved_vel.emit(velocity)
		player_moved_pos.emit(self.global_position)

# INPUT HANDLING

func _unhandled_input(event: InputEvent) -> void:
	# Flip sprite based on mouse X position
	turn_character(get_global_mouse_position().x < $Character.global_position.x)
	var attacks := attack_sys.get_available_attacks()
	var selected_attack: String = ""
	var precidence: float = -INF
	for attack in attacks:
		if attacks[attack].condition_matches(event):
			if precidence < attacks[attack].precidence:
				selected_attack = attack
	if selected_attack != "":
		print(get_global_mouse_position(), $Character.global_position)
		attack_sys.trigger_attack(selected_attack, get_global_mouse_position())
	attack_sys.update_weapon_pos(get_global_mouse_position())

# Flips character and dust sprite
func turn_character(to_west: bool):
	$Character.flip_h = to_west
	$Dust.flip_h = to_west
