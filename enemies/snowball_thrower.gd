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
	var snowball: Projectile = projectile.instantiate()
	snowball.set_direction(player.position - position)
	add_sibling(snowball)
	snowball.position = position
	print(snowball.position)
