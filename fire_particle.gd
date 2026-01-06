extends Sprite2D

var target = Vector2.ZERO
var duration = 0.5

func _ready() -> void:
	$Timer.start(duration)

func _physics_process(delta: float) -> void:
	position += target * delta / duration
	
func _on_timer_timeout() -> void:
	queue_free()
