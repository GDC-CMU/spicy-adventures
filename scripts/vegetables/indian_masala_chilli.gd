extends Vegetable

func use(player: Player):
	player.add_heat(30)
	player.change_attack(attack_scene.instantiate())
