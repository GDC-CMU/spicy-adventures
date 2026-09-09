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
	_clear_offers()
	upgrade_list = original.duplicate()

func refresh():
	_clear_offers()
	for i in range(mini(3, upgrade_list.size())):
		var upgrade: Upgrade = upgrade_list.pick_random()
		add_child(upgrade)
		upgrade.position = get_child(i + 1).position
		upgrade_list.erase(upgrade)
		on_screen.push_back(upgrade)

func confirm():
	if not is_instance_valid(selected) or selected not in on_screen:
		return
	var choice = selected
	_clear_offers()
	choice.buy(get_parent().player)
	if not choice.repeat:
		upgrade_list.erase(choice)
	get_parent().next_level()

func _clear_offers() -> void:
	for upgrade in on_screen:
		remove_child(upgrade)
		if upgrade not in upgrade_list:
			upgrade_list.push_back(upgrade)
	on_screen.clear()
	selected = null

func _exit_tree() -> void:
	for upgrade in original:
		if is_instance_valid(upgrade) and upgrade.get_parent() == null:
			upgrade.free()
