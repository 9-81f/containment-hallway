class_name InventoryComponent extends Node
		
@export var owner_entity: Node2D
var max_capacity := 4
var inventory: Dictionary[String, BaseItem.ItemData]
var selected_item: BaseItem.ItemData
var info_text: String = ''
var current_info_text: String = ''

##UI related
@onready var inventory_ui: CanvasLayer = $InventoryUI
@onready var tab_container: TabContainer = $InventoryUI/CenterContainer/VBoxContainer/HBoxContainer/TabContainer
@onready var item_name_label: Label = $InventoryUI/CenterContainer/VBoxContainer/HBoxContainer/PanelContainer/VBoxContainer/ItemName
@onready var item_desc_label: RichTextLabel = $InventoryUI/CenterContainer/VBoxContainer/HBoxContainer/PanelContainer/VBoxContainer/ItemDescription
@onready var use_btn: Button = $InventoryUI/CenterContainer/VBoxContainer/GridContainer/UseButton
@onready var drop_btn: Button = $InventoryUI/CenterContainer/VBoxContainer/GridContainer/DropButton
@onready var info_label: Label = $InventoryUI/CenterContainer/VBoxContainer/InfoLabel
@onready var info_timer: Timer = $InventoryUI/CenterContainer/VBoxContainer/InfoTimer
var _is_ui_open: bool = false

##Signals
signal item_used(item_data: BaseItem.ItemData, amount: int)
signal item_dropped(item_data: BaseItem.ItemData, amount: int)

func _ready() -> void:
	inventory_ui.hide()
	use_btn.pressed.connect(_use_item)
	drop_btn.pressed.connect(drop_item)
	info_timer.timeout.connect(_hide_info_text)
	tab_container.tab_changed.connect(func(_i: int): _refresh_ui())

#region Public Methods
func store(item: BaseItem) -> void:
	#if inventory.size() >= max_capacity: 
		#info_text = "Inventory is full! Increase max. capacity to hold more items."
		#return
		
	var new_item_data := _instantiate_new_item_data(item)
		
	if inventory.has(new_item_data.item_name):
		var found := inventory[new_item_data.item_name]
		if found.quantity < found.max_quantity:
			var available_quantity := found.max_quantity - found.quantity
			var can_take: int = min(available_quantity, new_item_data.quantity)
			found.quantity += can_take
			item.quantity -= can_take
		else:
			info_text = "Max. quantity of %s has been reached!" % found.item_name
	else:
		inventory[new_item_data.item_name] = new_item_data

func _instantiate_new_item_data(item: BaseItem) -> BaseItem.ItemData:
	var new_item_data: BaseItem.ItemData
	
	if item is Consumable:
		new_item_data = Consumable.ConsumableData.new()
		new_item_data.map_item_to_consumable_data(item)
	elif item is KeyItem:
		new_item_data = KeyItem.KeyItemData.new()
		new_item_data.map_item_to_key_item_data(item)
	elif item is Weapon:
		new_item_data = Weapon.WeaponData.new()
		new_item_data.map_item_to_weapon_data(item)
	else:
		new_item_data = BaseItem.ItemData.new()
		new_item_data.map_item_to_item_data(item)
	
	return new_item_data

func _use_item(amount: int = 1) -> void:
	if selected_item is not BaseItem.ItemData: return
	if !selected_item.usable: return
	item_used.emit(selected_item, amount)
	_refresh_ui()
	_show_info_text()

func drop_item(amount: int = 1) -> void:
	if !selected_item.droppable: return
	if !inventory.has(selected_item.item_name):
		push_error("Item not found in inventory!")
		return
		
	var found := inventory[selected_item.item_name]
	
	if found:
		found.quantity -= clamp(found.quantity, 0, amount)
		
	if found.quantity <= 0:
		inventory.erase(found.item_name)
		
	item_dropped.emit(found, amount)
	
	_refresh_ui()

func increase_capacity(to: int) -> void:
	max_capacity += to
#endregion

func _process(_delta: float) -> void:
	if owner_entity is PlayerController:
		owner_entity.debug.watch("Inventory: ", str(inventory.values()))
	if Input.is_action_just_pressed("inventory"):
		if _is_ui_open and can_process():
			get_viewport().set_input_as_handled()
			hide_ui()
		else:
			open_ui()

#region Inventory UI
func open_ui() -> void:
	if inventory.is_empty(): return
		
	_is_ui_open = true
	inventory_ui.show()
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	
	_refresh_ui()
			
	get_tree().paused = true
	
func hide_ui() -> void:
	inventory_ui.hide()
	_is_ui_open = false
	
	await get_tree().process_frame
	
	process_mode = Node.PROCESS_MODE_INHERIT
	get_tree().paused = false
	
func _refresh_ui() -> void:
	var existing_buttons: Dictionary[StringName, Button] = {}
	var current_tab: Control = tab_container.get_current_tab_control()
	var filtered_inventory := _filter_inventory_by_current_tab(current_tab)
	var grid_container: GridContainer = current_tab.get_child(0)
	
	for child in grid_container.get_children():
		if child is Button:
			existing_buttons[child.name] = child
	
	for item_name in filtered_inventory.keys():
		var item_data := filtered_inventory[item_name]
		
		if existing_buttons.has(item_name):
			var existing_button: Button = existing_buttons[item_data.item_name]
			existing_button.text = str(item_data.quantity)
			existing_button.icon = item_data.icon
			existing_buttons.erase(item_name)
		else:
			var button: Button = _create_item_slot(item_data)
			grid_container.add_child(button)
		
	for button_name in existing_buttons:
		existing_buttons[button_name].queue_free()
		
	if grid_container.get_child_count() > 0:
		# ensure buttons are all ready after first frame passed
		await get_tree().process_frame
		
		var first_button: Button = grid_container.get_child(0)
		
		if first_button:
			var tab_bar := tab_container.get_tab_bar()
			tab_bar.focus_neighbor_bottom = first_button.get_path()
			first_button.focus_neighbor_top = tab_bar.get_path()
			
	tab_container.get_tab_bar().grab_focus()
	
func _create_item_slot(item_data: BaseItem.ItemData) -> Button:
	var button = Button.new()
	button.name = item_data.item_name
	button.icon = item_data.icon
	button.text = str(item_data.quantity)
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	button.expand_icon = true
	button.custom_minimum_size = Vector2(32, 32)
	button.focus_mode = Control.FOCUS_ALL
	
	## Connect button signals on create only
	button.focus_entered.connect(_select_item.bind(item_data))
	button.focus_exited.connect(_unselect_item)
	button.pressed.connect(_use_item.bind(item_data, 1)) ## Improvements: dynamic amount using counter
	return button

func _filter_inventory_by_current_tab(current_tab: Control) -> Dictionary[String, BaseItem.ItemData]:
	var tab_index: int = tab_container.get_tab_idx_from_control(current_tab)
	var filtered_inventory: Dictionary[String, BaseItem.ItemData]
	
	for item_name in inventory.keys():
		match tab_index:
			0:
				if inventory[item_name] is Consumable.ConsumableData:
					filtered_inventory[item_name] = inventory[item_name]
			1:
				if inventory[item_name] is Weapon.WeaponData:
					filtered_inventory[item_name] = inventory[item_name]
			2:
				if inventory[item_name] is KeyItem.KeyItemData:
					filtered_inventory[item_name] = inventory[item_name]
	
	return filtered_inventory
	
func _show_info_text() -> void:
	if current_info_text != info_text:
		current_info_text = info_text
		info_text = ""
	
	if current_info_text:
		info_label.show()
		info_label.text = current_info_text
		info_timer.start()
	
	else:
		_hide_info_text()

func _hide_info_text() -> void:
	info_label.text = ""
	current_info_text = ""
	info_label.hide()
	
#endregion
	
#region On Focus Entered & Exited
func _select_item(item: BaseItem.ItemData) -> void:
	selected_item = item
	item_name_label.text = item.item_name
	item_desc_label.text = item.description

func _unselect_item() -> void:
	selected_item = null
	item_name_label.text = ""
	item_desc_label.text = ""
#endregion

func get_key_items() -> Array[KeyItem.KeyItemData]:
	var keys: Array[KeyItem.KeyItemData]
	
	for item_name in inventory.keys():
		var item := inventory[item_name]
		if item is KeyItem.KeyItemData:
			keys.append(item)
	
	return keys
