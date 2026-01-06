extends Vegetable

func use(player: Player):
	player.add_heat(35)
	player.change_attack(attack_scene.instantiate())
