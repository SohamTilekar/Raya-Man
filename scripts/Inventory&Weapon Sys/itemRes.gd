class_name Item extends Resource
@export var name: String
@export var texture: Texture # Texture to show in inventory
@export var droped_item_texture: Texture = null # Texture to show In Game when item is droped, If null then use same texture
@export var inhand_texture: Texture = null # Texture to show when item is hold in hand, If null then use same texture
@export var scene: PackedScene = null # Scene to show In Game, Placed on a Perticular tile, can be empty
@export var stack_size: int
@export var can_hold_in_hand: bool = false
@export var hand_hold_offset: Vector2
