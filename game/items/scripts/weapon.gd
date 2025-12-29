class_name Weapon extends BaseItem

enum WeaponType {
	RANGED,
	MELEE,
}

@export var damage := 1
@export var attack_speed := 200
@export var type: WeaponType = WeaponType.MELEE
@export var equip_scene: PackedScene

class WeaponData extends ItemData:	
	var damage: int
	var attack_speed: int
	var type: WeaponType
	var equip_scene: PackedScene
	var equip_animation: SpriteFrames
	
	func map_item_to_weapon_data(item: Weapon) -> void:
		item.droppable = false
		map_item_to_item_data(item)
		damage = item.damage
		attack_speed = item.attack_speed
		type = item.type
		equip_scene = item.equip_scene
