extends Projectile

func hit_player(player: Player) -> void:
	player.take_damage(7, true)
