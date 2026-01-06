extends Attack

var rng = RandomNumberGenerator.new()

func _process(delta: float) -> void:
	_on_particle_spawn_timeout()

func _on_particle_spawn_timeout() -> void:
	var new_particle = fire_particle_scene.instantiate()
	add_child(new_particle)
	new_particle.target = (Vector2.RIGHT * 400).rotated(-rng.randf_range(PI/30, PI/2 - PI/30) + PI/4)
