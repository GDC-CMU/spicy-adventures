extends Vegetable

func use(player: Player):
	player.add_heat(10)
	player.vietnamese_chilli_bonus += 1
	pass
