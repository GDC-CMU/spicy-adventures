extends SceneTree
## Run on the staged native machine, not as a global input mapper.
## --script res://tools/controller_probe.gd -- --arcade --arcade-controller-log

const Controls = preload("res://arcade/controls.gd")

class Probe:
	extends Control

	var status: Label

	func _ready() -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var background := ColorRect.new()
		background.color = Color("#10283a")
		background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(background)
		status = Label.new()
		status.position = Vector2(28, 24)
		status.size = Vector2(1096, 600)
		status.add_theme_font_size_override("font_size", 28)
		status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		add_child(status)
		status.text = "Spicy Adventure — controller probe\n\nTest BOTH connected slots.\nB raw 0 → normalized 1: back/pause\nA raw 1 → normalized 0: eat\nX raw 2 → normalized 2: heat\nY raw 3 → normalized 3: discard\nCoin raw 4 → normalized 5: unbound\nP1 raw 5 → normalized 9: pause/back\nSelect raw 8 → normalized 4: pause/back\nStart raw 9 → normalized 6: confirm\n\nStick: axes 0/1 or normalized D-pad 11–14.\nEscape exits this diagnostic."
		for device in Input.get_connected_joypads():
			print("SPICY_ARCADE_CONTROLLER ", JSON.stringify(Controls.describe_device(device)))

	func _input(event: InputEvent) -> void:
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			get_tree().quit(0)
		if event is InputEventJoypadButton or event is InputEventJoypadMotion:
			var actions: Array[String] = []
			for action in Controls.RELEASE_ACTIONS:
				if event.is_action_pressed(action):
					actions.append(action)
			var message := "device=%d normalized=%s actions=%s" % [
				event.device, event.as_text(), ", ".join(actions)]
			print("SPICY_ARCADE_INPUT ", message)
			status.text = status.text.get_slice("\n\nLast input:", 0) + "\n\nLast input:\n" + message


func _initialize() -> void:
	root.add_child.call_deferred(Probe.new())
