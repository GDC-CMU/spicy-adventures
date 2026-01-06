extends Node2D

@export var upgrade_list_scene: Array[PackedScene]
var upgrade_list: Array[Upgrade]
var on_screen: Array[Upgrade]
var selected: Upgrade = null
var original: Array[Upgrade]

func _ready() -> void:
	for upgrade_scene in upgrade_list_scene:
		upgrade_list.push_back(upgrade_scene.instantiate())
	original = upgrade_list.duplicate(true)

func reset() -> void:
	upgrade_list = original.duplicate(true)

func refresh():
	selected = null
	for i in range(3):
		var upgrade: Upgrade = upgrade_list.pick_random()
		add_child(upgrade)
		upgrade.position = get_child(i + 1).position
		upgrade_list.erase(upgrade)
		on_screen.push_back(upgrade)

func confirm():
	if not selected:
		return
	for upgrade in on_screen:
		remove_child(upgrade)
		upgrade_list.push_back(upgrade)
	
	on_screen.clear()
	selected.buy(get_parent().player)
	
	if not selected.repeat:
		upgrade_list.erase(selected)
	
	get_parent().next_level()
	
