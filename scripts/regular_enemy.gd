extends CharacterBody2D

@export var speed: float = 100.0
@export var max_health: float = 10
var burn: float = 0
var health: float

var player: Node2D

func _ready() -> void:
	health = max_health
	player = get_parent().get_node("Player")
	
func _physics_process(_delta: float) -> void:
	if player:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()
	health -= burn * _delta
	if health < 0:
		queue_free()

func set_burn(value: float) -> void:
	burn = value
