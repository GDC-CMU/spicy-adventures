extends Area2D

@export var duration = 0.5
@export var pre_duration = 1.0
var scale_relative_start = 0.5
var original_scale

func _physics_process(delta: float) -> void:
	if not $Timer.is_stopped():
		$Snowball.position += -$StartPoint.position * delta / duration
		$Snowball.scale += (original_scale - original_scale*scale_relative_start) * delta / duration

func _ready() -> void:
	$Snowball.position = $StartPoint.position
	original_scale = $Snowball.scale
	$Snowball.scale *= scale_relative_start
	$ThrowTimer.start(pre_duration)
	$Snowball.hide()
	
func _on_timer_timeout() -> void:
	for node in get_overlapping_bodies():
		if node is Player:
			node.effect_speed(0.3, 1)
			node.take_damage(5)
	queue_free()


func _on_throw_timer_timeout() -> void:
	$Timer.start(duration)
	$Snowball.show() # Replace with function body.
