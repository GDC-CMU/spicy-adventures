class_name Enemy
extends CharacterBody2D

@export var speed: float = 100.0
@export var max_health: float = 10
var burn: float = 0
@export var damage: float = 5
var health: float
var player: Player

func melee_attack(collision_info: KinematicCollision2D) -> bool:
	if collision_info:
		var object = collision_info.get_collider()
		if object is Player:
			if object.take_damage(damage, true):
				var vec: Vector2 = object.position - position
				object.knockback(vec.normalized() * 100)
				return true
	return false

func _ready() -> void:
	health = max_health
	if get_parent().has_node("Player"):
		player = get_parent().get_node("Player")
	
func set_facing() -> void:
	if velocity != Vector2.ZERO:
		var angle_radians = atan2(velocity.x, velocity.y)
		if angle_radians > 0 and angle_radians < PI:
			$Sprite2D.flip_h = false
		if angle_radians < 0 and angle_radians > -PI:
			$Sprite2D.flip_h = true
		

func die():
	Stats.enemies_killed += 1
	queue_free()

func _physics_process(delta: float) -> void:
	health -= burn * delta
	if health <= 0:
		die()
	$HealthBar.set_value_no_signal(100 * health/max_health)
	set_facing()
	
func set_burn(value: float) -> void:
	burn = value
