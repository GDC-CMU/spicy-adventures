class_name SpikeWall
extends Node2D

@export var gaps = 50
@export var spikes: PackedScene
@export var health = 10
var counter = 0

func get_vector() -> Vector2:
	return $Line2D.points[1] - $Line2D.points[0]
	
func set_line(a: Vector2, b: Vector2):
	$Line2D.points[0] = a
	$Line2D.points[1] = b

func get_distance():
	return $Line2D.points[0].distance_to($Line2D.points[1])

func spawn_new():
	if counter*gaps > get_distance():
		return
	var new_spike: Enemy = spikes.instantiate()
	add_child(new_spike)
	new_spike.health = health
	new_spike.max_health = health
	new_spike.position = get_vector().normalized() * counter * gaps + $Line2D.points[0]
	counter += 1
	
func start_spawning():
	$SpawnTimer.start()

func _ready() -> void:
	start_spawning()
	$Line2D.hide()
