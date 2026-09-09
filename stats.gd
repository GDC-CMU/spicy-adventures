extends Node

var enemies_killed = 0
var health_lost = 0
var start_time = 0
var max_burn = 0
var paused_at = -1
var paused_msec = 0

func reset():
	enemies_killed = 0
	health_lost = 0
	max_burn = 0
	start_time = Time.get_ticks_msec()
	paused_at = -1
	paused_msec = 0

func pause_run() -> void:
	if paused_at < 0:
		paused_at = Time.get_ticks_msec()

func resume_run() -> void:
	if paused_at >= 0:
		paused_msec += Time.get_ticks_msec() - paused_at
		paused_at = -1

func calculate() -> Array[int]:
	var end_time = paused_at if paused_at >= 0 else Time.get_ticks_msec()
	return [enemies_killed, health_lost, max_burn, maxi(0, end_time - start_time - paused_msec)]
