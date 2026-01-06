@abstract
class_name Vegetable
extends Area2D

@export var attack_scene: PackedScene
@export var rotten: PackedScene
@export var id: String
@export var repeat = false

@export var target_position = Vector2(0, 0)
var speed = 0.7

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("pick_up"):
		body.pick_up(self)

func rot():
	var new_rotten: Vegetable = rotten.instantiate()
	add_sibling(new_rotten)
	new_rotten.position = position
	new_rotten.target_position = target_position
	queue_free()

func _physics_process(delta: float) -> void:
	position += (target_position - position) * speed * delta
@abstract
func use(player: Player)
