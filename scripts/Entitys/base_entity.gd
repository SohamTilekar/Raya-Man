class_name BaseEntity extends CharacterBody2D

signal health_changed(curr: float, max_val: float)

@export var max_health: float = 100.0
@onready var current_health: float = max_health:
	set(val):
		current_health = clamp(val, 0.0, max_health)
		health_changed.emit(current_health, max_health)
		if current_health <= 0.0:
			_die()

var debug_attack_center: Vector2 = Vector2.ZERO
var debug_attack_radius: float = 0.0
var debug_attack_timer: float = 0.0

func _process(delta: float) -> void:
	if debug_attack_timer > 0.0:
		debug_attack_timer -= delta
		queue_redraw()

func take_damage(amount: float) -> void:
	current_health -= amount
	print(name, " took ", amount, " damage. HP: ", current_health)

func _die() -> void:
	queue_free()

func _draw() -> void:
	if debug_attack_timer > 0.0:
		# Draw the attack collision area as a semi-transparent red circle with outline
		draw_circle(debug_attack_center - global_position, debug_attack_radius, Color(1, 0, 0, 0.25))
		draw_arc(debug_attack_center - global_position, debug_attack_radius, 0, TAU, 32, Color(1, 0, 0, 0.8), 1.0, true)

