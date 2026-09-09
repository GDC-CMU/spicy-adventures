extends Enemy

@export var snowball: PackedScene
@export var wall_scene: PackedScene
@export var small_snowball: PackedScene
@export var shards: PackedScene
@export var enemy_list: Array[PackedScene]
@export var spawner_scene: PackedScene
var rng = RandomNumberGenerator.new()

var wander_direction: Vector2 = Vector2(0, 0)

func new_wander_direction():
	wander_direction = Vector2.RIGHT.rotated(rng.randf_range(0, PI*2))*speed

func _ready() -> void:
	super._ready()
	new_wander_direction()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	velocity = wander_direction
	move_and_slide()

func summon_snowball() -> void:
	for i in range(4):
		var new_snowball: Node2D = snowball.instantiate()
		add_sibling(new_snowball)
		new_snowball.position = player.position + (Vector2.RIGHT * i * 100).rotated(rng.randf_range(0, PI*2))

func summon_walls() -> void:
	for i in range(8):
		var new_wall: SpikeWall = wall_scene.instantiate()
		add_sibling(new_wall)
		new_wall.set_line(position, position + (Vector2.RIGHT * 2000).rotated(i * PI/4))

func projectile_wave(count: int, offset: float, projectile_scene: PackedScene):
	for i in range(count):
		var new_projectile: Projectile = projectile_scene.instantiate()
		add_sibling(new_projectile)
		new_projectile.position = position
		new_projectile.set_direction(Vector2.RIGHT.rotated((PI*2/count) * i + offset))

func projectile_spiral(count: int, duration: float, projectile_scene: PackedScene):
	for i in range(count):
		var new_projectile: Projectile = projectile_scene.instantiate()
		add_sibling(new_projectile)
		new_projectile.position = position
		new_projectile.set_direction(Vector2.RIGHT.rotated((PI*2/count) * i))
		await get_tree().create_timer(duration / count, false).timeout

func multi_spiral():
	var count = 18
	var duration = 1
	projectile_spiral(count, duration, shards)
	await  get_tree().create_timer(duration, false).timeout
	projectile_spiral(count, duration, small_snowball)
	await  get_tree().create_timer(duration, false).timeout
	projectile_spiral(count, duration, shards)
	await  get_tree().create_timer(duration, false).timeout
	projectile_spiral(count, duration, small_snowball)
	

func multi_wave():
	var count = 18
	var delay = 0.4
	projectile_wave(count, 0, shards)
	await get_tree().create_timer(delay, false).timeout
	projectile_wave(count, PI/count, shards)
	await get_tree().create_timer(delay, false).timeout
	projectile_wave(count, 0, small_snowball)
	await get_tree().create_timer(delay, false).timeout
	projectile_wave(count, PI/count, small_snowball)

func spawn_spawners():
	var spawner1: Spawner = spawner_scene.instantiate()
	add_sibling(spawner1)
	spawner1.position = position + Vector2.RIGHT * 300
	spawner1.spawnable_scenes = enemy_list
	var spawner2: Spawner = spawner_scene.instantiate()
	add_sibling(spawner2)
	spawner2.position = position + Vector2.LEFT * 300
	spawner2.spawnable_scenes = enemy_list
	

var attack_list: Array[Callable] = [spawn_spawners, multi_wave, multi_spiral, summon_walls, summon_snowball]

func attack() -> void:
	attack_list.pick_random().call()

func die():
	get_parent().win()
