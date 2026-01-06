extends Area2D

func _ready() -> void:
	$ColorRect.position = $CollisionShape2D.position - $CollisionShape2D.shape.get_rect().size/2
	$ColorRect.size = $CollisionShape2D.shape.get_rect().size
