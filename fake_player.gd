extends Sprite2D

var attack: Attack = null

func change_attack(new_attack):
	if attack:
		attack.queue_free()
	if new_attack:
		attack = new_attack
		add_child(attack)
