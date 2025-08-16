class_name Weapon extends Item

enum AttackType {
	Sword
}
## CoolDown for AI
@export var cooldown: float
@export var attack_condition: AttackCondition
@export var attack_types: Array[AttackType]
@export var attack_effect_texture: Texture
@export var attack_effect_atlass: Array[WeaponAttackEffect]
@export var attack_distance: float
@export var attack_radius: float
@export var attack_duration: float
@export var combo_lifespan: float # for sword
@export var return_duration: float
