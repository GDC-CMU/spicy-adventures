extends Node2D

func set_text():
	var results = Stats.calculate()
	var text = ""
	text += "Enemies killed: " + str(results[0]) + "\n"
	text += "Health Lost: " + str(results[1]) + "\n"
	text += "Maximum burn damage: " + str(results[2]) + "\n"
	var seconds: int = results[3] / 1000
	text += "Time taken: " + str(seconds / 60) + " minutes " + str(seconds % 60) + " seconds" + "\n"
	$RichTextLabel.text = text
