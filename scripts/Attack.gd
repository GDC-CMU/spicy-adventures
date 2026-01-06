class_name Attack
extends Area2D

const offset = PI/30

@export var damage: float = 5.0
@export var fire_particle_scene: PackedScene

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("set_burn"):
		body.set_burn(damage)

func _on_body_exited(body: Node2D) -> void:
	if body.has_method("set_burn"):
		body.set_burn(0)
