class_name CombatComponent extends Node

signal weapon_equipped
signal weapon_unequipped

@export var owner_entity: Node
@onready var weapon_holder: Marker2D = $WeaponHolder
var current_weapon: WeaponEquip = null

var is_attacking := false
	
func equip_weapon(weapon_data: Weapon.WeaponData) -> void:
	if !weapon_data: return
	
	unequip()
		
	current_weapon = weapon_data.equip_scene.instantiate()
	
	current_weapon.set_weapon_data(weapon_data)
	
	current_weapon.att_started.connect(func(): is_attacking = true)
	current_weapon.att_finished.connect(func(): is_attacking = false)
	current_weapon.hit_made.connect(_on_hit_made)
	
	weapon_holder.add_child(current_weapon)
	
	weapon_equipped.emit()
	
func unequip() -> void:
	if current_weapon:
		current_weapon.queue_free()
		current_weapon = null
	weapon_unequipped.emit()

func _attack() -> void:
	if owner_entity is PlayerController:
		current_weapon.melee(owner_entity.last_facing_prefix)
	
func _process(_delta: float) -> void:
	if !current_weapon: return
	
	if owner_entity is PlayerController:
		if !owner_entity.current_state == PlayerController.PlayerState.ATTACK:
			if Input.is_action_just_pressed("attack"):
				_attack()

		if current_weapon:
			if owner_entity.currently_facing == PlayerController.Facing.LEFT: 
				current_weapon.scale.x = -1.0
			else:
				current_weapon.scale.x = 1.0
			
			if owner_entity.currently_facing == PlayerController.Facing.BACK:
				current_weapon.z_index = -1
			else:
				current_weapon.z_index = 0
				
			if !owner_entity.current_state == PlayerController.PlayerState.PUSH:
				current_weapon.show()
				current_weapon.hold(owner_entity.last_facing_prefix, owner_entity.PlayerState.keys()[owner_entity.current_state].to_lower())
			else:
				current_weapon.hide()

func _on_hit_made() -> void:
	if owner_entity is PlayerController:
		owner_entity.camera.shake()
