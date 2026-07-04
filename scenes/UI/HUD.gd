extends CanvasLayer

@onready var health_bar: ProgressBar = $MarginContainer/VBoxContainer/HealthContainer/HealthBar
@onready var mana_bar: ProgressBar = $MarginContainer/VBoxContainer/ManaContainer/ManaBar
@onready var stamina_bar: ProgressBar = $MarginContainer/VBoxContainer/StaminaContainer/StaminaBar
@onready var level_label: Label = $MarginContainer/VBoxContainer/LevelLabel

func _ready() -> void:
	# Fallback auto-detection of Player in the GameWorld scene
	var player = get_node_or_null("/root/GameWorld/YSorting/Player")
	if player:
		initialize(player)

func initialize(player: CharacterBody2D) -> void:
	if player:
		if player.has_signal("health_changed"):
			player.health_changed.connect(_on_health_changed)
		if player.has_signal("mana_changed"):
			player.mana_changed.connect(_on_mana_changed)
		if player.has_signal("stamina_changed"):
			player.stamina_changed.connect(_on_stamina_changed)
		if player.has_signal("level_changed"):
			player.level_changed.connect(_on_level_changed)
		
		# Set initial values
		_on_health_changed(player.current_health, player.max_health)
		_on_mana_changed(player.current_mana, player.max_mana)
		_on_stamina_changed(player.current_stamina, player.max_stamina)
		_on_level_changed(player.level)

func _on_health_changed(curr: float, max_val: float) -> void:
	health_bar.max_value = max_val
	health_bar.value = curr

func _on_mana_changed(curr: float, max_val: float) -> void:
	mana_bar.max_value = max_val
	mana_bar.value = curr

func _on_stamina_changed(curr: float, max_val: float) -> void:
	stamina_bar.max_value = max_val
	stamina_bar.value = curr

func _on_level_changed(lvl: int) -> void:
	level_label.text = "LEVEL: %d" % lvl
