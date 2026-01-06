extends Node

var enemies_killed = 0
var health_lost = 0
var start_time = 0
var max_burn = 0

func reset():
	enemies_killed = 0
	health_lost = 0
	max_burn = 0
	start_time = Time.get_ticks_msec()
	
func calculate() -> Array[int]:
	return [enemies_killed, health_lost, max_burn, Time.get_ticks_msec() - start_time]
