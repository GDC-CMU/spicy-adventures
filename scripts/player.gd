class_name Player
extends CharacterBody2D

@export var speed: float = 500.0
@export var friction: float = 4
@export var max_health: float = 100
@export var max_heat: float = 100
@export var heat_usage: float = 10
var health
var heat
var bonus_burn = 0
var current_attack: Attack = null
var emergency_heat_unlocked = false
var available_emergency_heat = false
var can_discard = false
var is_hyper = false
var is_invicible = false

var transmutation_copy = false

var combo_unlocked = false
var combo_multiplier = 1

var last_pepper: String = ""
var vietnamese_chilli_bonus = 0

var speed_multiplier = 1
var burn_multiplier = 1

var eat_penalty = 0

var knockback_vec: Vector2

func effect_speed(multiplier: float, duration: float):
	#print(multiplier, duration)
	speed_multiplier *= multiplier
	await get_tree().create_timer(duration).timeout
	speed_multiplier /= multiplier

func get_total_bonus():
	return vietnamese_chilli_bonus + bonus_burn

func reset() -> void:
	$BonusHUD.reset()
	$Queue.clear()
	combo_multiplier = 1
	last_pepper = ""
	vietnamese_chilli_bonus = 0
	health = max_health
	heat = 0
	remove_attack()
	velocity = Vector2(0, 0)
	position = Vector2(0, 0)
	if emergency_heat_unlocked:
		available_emergency_heat = true
	$CollisionShape2D.disabled = true

func spanw_in() -> void:
	$CollisionStartTimer.start()

func _ready() -> void:
	health = max_health
	heat = 0

func remove_attack():
	if current_attack:
		remove_child(current_attack)
		current_attack = null
		$FireSound.stop()
	$BonusHUD.set_current_burn(0)

func change_attack(attack: Attack):
	remove_attack()
	current_attack = attack
	current_attack.damage += get_total_bonus()
	current_attack.damage *= get_multiplier()
	vietnamese_chilli_bonus = 0
	$BonusHUD.set_current_burn(current_attack.damage)
	Stats.max_burn = max(Stats.max_burn, current_attack.damage)
	add_child(current_attack)
	$FireSound.play()
	change_facing()
		
func knockback(vec: Vector2):
	knockback_vec += vec * 5
	await get_tree().create_timer(0.2).timeout
	knockback_vec -= vec * 5

func change_facing() -> void:
	var angle_radians = atan2(velocity.x, velocity.y)
	if current_attack:
		current_attack.rotation = -angle_radians + PI * 0.5
	if angle_radians > 0 and angle_radians < PI:
		$Sprite2D.flip_h = false
	if angle_radians < 0 and angle_radians > -PI:
		$Sprite2D.flip_h = true

func reduce_heat(value: float):
	if heat > 0:
		heat -= value
		if heat < 0:
			remove_attack()
			heat = 0

func set_level_label(value: int):
	if value == 10:
		$LevelLabel.text = "Finale"
	elif value == 11:
		$LevelLabel.text = "Tutorial"
	else:
		$LevelLabel.text = "Level " + str(value)

func _physics_process(delta: float) -> void:
	var new_velocity = Vector2(0, 0)
	if Input.is_action_pressed("ui_left"):
		new_velocity.x = -1
	if Input.is_action_pressed("ui_right"):
		new_velocity.x = 1
	if Input.is_action_pressed("ui_up"):
		new_velocity.y = -1
	if Input.is_action_pressed("ui_down"):
		new_velocity.y = 1 
	if Input.is_action_just_pressed("emergency heat"):
		if available_emergency_heat:
			add_heat(100)
			available_emergency_heat = false
	if Input.is_action_just_pressed("cheat_speed"):
		speed = 1000
		burn_multiplier = 1000
	if Input.is_action_just_pressed("discard"):
		if can_discard:
			pop_queue()
	if new_velocity != Vector2(0, 0):
		velocity = new_velocity
		velocity *= speed * speed_multiplier
		change_facing()
	else:
		velocity -= velocity * friction * delta
	var no_knockback = velocity
	velocity += knockback_vec
	#print(velocity)
	move_and_slide()
	velocity = no_knockback
	if Input.is_action_just_pressed("use"):
		use_vegetable()
	
	reduce_heat(heat_usage * delta)
	$HealthBar.set_value_no_signal(100 * health / max_health)
	$HeatBar.set_value_no_signal(100 * heat / max_heat)
	$BonusHUD.set_next_bonus(get_total_bonus())
	$BonusHUD.set_next_multiplier(get_multiplier())

func get_multiplier():
	return burn_multiplier * combo_multiplier

func use_vegetable() -> void:
	var res = $Queue.use()
	if res == "":
		return
	
	take_damage(eat_penalty)
	
	if is_hyper:
		effect_speed(1.5, 0.5)
	
	if combo_unlocked:
		if res == last_pepper:
			combo_multiplier += 0.2
		else:
			last_pepper = res
			combo_multiplier = 1
	
	$EatSound.stop()
	$EatSound.play()

func pop_queue() -> void:
	$Queue.pop_queue()

func pick_up(vegetable: Vegetable):
	$Queue.push.call_deferred(vegetable)

func trigger_invisibility():
	is_invicible = true
	$Sprite2D.self_modulate.a = 0.5
	await get_tree().create_timer(0.5).timeout
	is_invicible = false
	$Sprite2D.self_modulate.a = 1

func take_damage(value: float, is_attack = false) -> bool:
	if is_attack:
		if is_invicible:
			return false
		trigger_invisibility()
	health -= value
	if value > 0:
		Stats.health_lost += value
	health = clamp(health, 0, max_health)
	if value > 0:
		$AudioStreamPlayer2D.play()
	if health == 0:
		get_parent().game_over()
	return true

func add_heat(value: float):
	heat += value
	heat  = min(heat, max_heat)

func _on_collision_start_timer_timeout() -> void:
	$CollisionShape2D.disabled = false


func _on_give_up_button_pressed() -> void:
	take_damage(100)
