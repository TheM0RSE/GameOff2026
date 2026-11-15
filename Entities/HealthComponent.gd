class_name HealthComponent
extends Node

signal health_changed(current_health: int)
signal damage_taken(amount: int)
signal died()

@export var max_health: int = 100

var current_health: int
var alive: bool = true

func _ready():
	current_health = max_health
	
func take_damage(amount):
	if not alive or amount <= 0: # Do nothing if entity is dead or if there is no damage
		return
	var actual_damage = clampi(amount, 0, current_health) # Do no more damage if it is more than the current health
	current_health = clampi(current_health - actual_damage, 0, max_health) # Take off the damage from the current health
	damage_taken.emit(actual_damage)
	health_changed.emit(current_health)
	
	if current_health <= 0:
		alive = false
		died.emit()
