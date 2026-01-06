class_name TreeP
extends Node2D

var rng = RandomNumberGenerator.new()
@export var available_vegetable_scenes: Array[PackedScene]

func spawn_vegetable() -> void:
	var veg: Vegetable = available_vegetable_scenes.pick_random().instantiate()
	add_sibling(veg)
	veg.position = position
	veg.target_position = (Vector2.RIGHT * rng.randf_range(0, 500)).rotated(rng.randf_range(0, PI*2)) + position
