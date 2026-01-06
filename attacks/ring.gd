extends Attack

@export var spin_speed: float = 1.0

func _physics_process(delta: float) -> void:
	$Sprite2D.rotate(delta * spin_speed * PI)
