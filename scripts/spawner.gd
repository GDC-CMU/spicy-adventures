class_name Spawner
extends Enemy

@export var spawnable_scenes: Array[PackedScene]
@export var spawn_rate: float = 2
@export var enemy_list: Array[PackedScene]
var rng = RandomNumberGenerator.new()

var spawning = false

func _on_spawn_timer_timeout() -> void:
	if not spawning:
		return
	var new_enemy: Enemy = spawnable_scenes.pick_random().instantiate()
	add_sibling(new_enemy)
	new_enemy.position = position + (player.position - position).normalized()*50


func _on_detection_range_body_entered(body: Node2D) -> void:
	if body is Player:
		spawning = true

func _on_detection_range_body_exited(body: Node2D) -> void:
	if body is Player:
		spawning = false

func _ready() -> void:
	super._ready()
	$SpawnTimer.wait_time = spawn_rate
