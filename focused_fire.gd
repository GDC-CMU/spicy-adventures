extends Attack

var rng = RandomNumberGenerator.new()

func _process(delta: float) -> void:
	_on_particle_spawn_timeout()

func _on_particle_spawn_timeout() -> void:
	var new_particle = fire_particle_scene.instantiate()
	add_child(new_particle)
	new_particle.target = (Vector2.RIGHT * 550)
	new_particle.duration += rng.randf_range(-0.1, 0.1)
