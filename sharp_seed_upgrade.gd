extends Upgrade

func buy(player: Player):
	player.burn_multiplier *= 2
	player.eat_penalty += 5
