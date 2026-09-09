extends Sprite2D

var attack: Attack = null

func change_attack(new_attack):
	if is_instance_valid(attack):
		attack.queue_free()
	attack = new_attack
	if attack:
		add_child(attack)
