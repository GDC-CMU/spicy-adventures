extends Node2D

var current_burn
var next_bonus
var next_multiplier

func reset():
	set_current_burn(0)
	set_next_bonus(0)
	set_next_multiplier(1)

func set_current_burn(value: float):
	current_burn = value
	$CurrentBurnLabel.text = str(value)
	
func set_next_bonus(value: float):
	next_bonus = value
	$NextBonusLabel.text = "+" + str(value)

func set_next_multiplier(value: float):
	next_multiplier = value
	$NextMultiplierLabel.text = "x" + str(value)
