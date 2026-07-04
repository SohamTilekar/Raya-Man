class_name Weapon extends Item

## CoolDown for AI
@export var cooldown_range: Vector2 = Vector2(NAN, NAN)
@export var movement: Attack.MovementType = Attack.MovementType.Sword_Sorrund_target
@export var defence_dist_min: float = NAN
@export var defence_dist_max: float = NAN

@export var attack_condition: AttackCondition
@export var attack_types: Array[Attack.AttackType]

@export var attack_effect_texture: Texture
@export var attack_effect_atlass: Array[WeaponAttackEffect]

@export var attack_distance: float = NAN
@export var attack_radius: float = NAN
@export var attack_duration: float = NAN
@export var combo_lifespan: float = NAN # for sword
@export var return_duration: float = NAN
@export var damage: float = 15.0

