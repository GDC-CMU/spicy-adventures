extends Projectile

func hit_player(player: Player) -> void:
	print("HIT")
	player.take_damage(5, true)
	player.reduce_heat(5)
