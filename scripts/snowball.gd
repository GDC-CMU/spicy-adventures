class_name Projectile
extends Area2D

var velocity: Vector2
@export var speed = 1000

func set_direction(vector: Vector2):
	velocity = vector.normalized() * speed
	var angle_radians = atan2(velocity.x, velocity.y)
	rotation = -angle_radians + PI / 2

func _physics_process(delta: float) -> void:
	position += velocity * delta

func hit_player(player: Player) -> void:
	pass
	
func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		self.hit_player(body)
		queue_free()
	
