extends Enemy

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if player:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * speed
		var collision_info = move_and_collide(velocity * delta)
		if melee_attack(collision_info):
			player.pop_queue()
