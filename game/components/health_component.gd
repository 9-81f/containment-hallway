class_name HealthComponent extends Node2D

signal health_changed(current_health: float, max_health: float)
signal health_depleted

@export var owner_entity: Node2D
@export var max_health := 2
var current_health := 0

func _ready() -> void:
	current_health = max_health

func _process(_delta: float) -> void:
	if current_health <= 0:
		zero()

func hurt(damage: int) -> void:
	current_health -= damage
	if current_health <= 0:
		current_health = 0
	health_changed.emit(current_health, max_health)
	
func heal(restore: int) -> void:
	current_health += restore
	if current_health >= max_health:
		current_health = max_health
	health_changed.emit(current_health, max_health)
	
func zero() -> void:
	health_depleted.emit()
