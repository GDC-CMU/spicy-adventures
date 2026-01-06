extends Sprite2D

func change_content(attack, description):
	$Description.text = description
	$FakePlayer.change_attack(attack)
