extends Enemy

var wander_direction: Vector2 = Vector2(0, 0)
@export var projectile: PackedScene
var rng = RandomNumberGenerator.new()

func new_wander_direction():
	wander_direction = Vector2.RIGHT.rotated(rng.randf_range(0, PI*2))*speed

func _ready() -> void:
	super._ready()
	new_wander_direction()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	velocity = wander_direction
	move_and_slide()
	
func _on_throw_timer_timeout() -> void:
	var shard1: Projectile = projectile.instantiate()
	var shard2: Projectile = projectile.instantiate()
	var shard3: Projectile = projectile.instantiate()
	
	var dir = player.position - position
	shard1.set_direction(dir.rotated(PI/5))
	shard2.set_direction(dir.rotated(0))
	shard3.set_direction(dir.rotated(-PI/5))
	
	shard1.position = position
	shard2.position = position
	shard3.position = position
	
	add_sibling(shard1)
	add_sibling(shard2)
	add_sibling(shard3)
	
