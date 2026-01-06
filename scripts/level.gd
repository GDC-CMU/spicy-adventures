class_name Level
extends Node2D

@export var regular_enemy_scene: PackedScene

func transmute():
	var new_list: Array[PackedScene] = []
	for node in get_children():
		if node is TreeP:
			if new_list.is_empty():
				node.available_vegetable_scenes.pop_at(0)
				new_list.append(node.available_vegetable_scenes.pick_random())
			print(new_list)
			node.available_vegetable_scenes = new_list
	

func _ready() -> void:
	pass
	#$fakeplayer.hide()

func spawn_enemy() -> void:
	var new_enemy = regular_enemy_scene.instantiate()
	add_child(new_enemy)

func game_over():
	get_parent().game_over()

func win():
	get_parent().win()

func _on_win_zone_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		get_parent().goto_upgrade()
