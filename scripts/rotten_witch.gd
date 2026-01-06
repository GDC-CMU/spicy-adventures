extends Enemy

var target: Vegetable = null

func _ready() -> void:
	super._ready()
	find_target()

func find_target():
	target = null
	for node in get_parent().get_children():
		if node is Vegetable and not (node is Rotten):
			if not target or position.distance_to(node.position) < position.distance_to(target.position):
				target = node

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if target:
		var direction = (target.position - position).normalized()
		velocity = direction * speed
		var collision_info = move_and_collide(velocity * delta)
		melee_attack(collision_info)
	else:
		find_target()

func _on_rot_range_area_entered(area: Area2D) -> void:
	if area is Vegetable and not (area is Rotten) and area.get_parent().name != "Queue":
		var veg: Vegetable = area
		veg.rot.call_deferred()
