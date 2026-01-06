extends Attack

var rng = RandomNumberGenerator.new()

func _process(delta: float) -> void:
	_on_particle_spawn_timeout()

func _on_particle_spawn_timeout() -> void:
	var new_particle = fire_particle_scene.instantiate()
	add_child(new_particle)
	
	new_particle.target = (Vector2.RIGHT * 450).rotated(rng.randf_range(-(PI/12) * 4 + offset, -(PI/12) * 2 - offset) )
	
	var new_particle2 = fire_particle_scene.instantiate()
	add_child(new_particle2)
	
	new_particle2.target = (Vector2.RIGHT * 450).rotated(-rng.randf_range(-(PI/12) * 4 + offset, -(PI/12) * 2 - offset) )
	
	var new_particle3 = fire_particle_scene.instantiate()
	add_child(new_particle3)
	new_particle3.target = (Vector2.LEFT * 200).rotated(rng.randf_range(-PI/12 + offset, PI/12 - offset))
	new_particle3.self_modulate = Color.BROWN
	new_particle3.self_modulate.a = 0.1
