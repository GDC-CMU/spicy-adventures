extends Vegetable

func use(player: Player):
	player.change_attack(attack_scene.instantiate())
	player.add_heat(50)
