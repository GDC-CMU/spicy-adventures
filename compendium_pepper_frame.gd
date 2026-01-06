extends Node2D

@export var vegetable_scene: PackedScene
@export_multiline var description: String
var vegetable: Vegetable

func _ready() -> void:
	vegetable = vegetable_scene.instantiate()
	vegetable.collision_mask = 0
	vegetable.collision_layer = 0
	add_child(vegetable)
	
func _on_button_pressed() -> void:
	var new_attack = vegetable.attack_scene.instantiate() if vegetable.attack_scene else null
	get_parent().change_content(new_attack, description) # Replace with function body.
