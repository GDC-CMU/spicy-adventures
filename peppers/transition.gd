extends CanvasLayer

func play_transition():
	$DissolveRect.modulate.a = 1
	$AnimationPlayer.play_backwards("Dissolve")
