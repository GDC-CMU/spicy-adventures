extends RefCounted
## SDL source indices are raw USB indices; InputEventJoypadButton is normalized.
## Overrides cover only the exact cabinet GUIDs observed in both Godot backends.

const CABINET_GUID = "03000000790000000600000010010000"
const CABINET_SDL_GUID = "0300457e790000000600000010010000"
const CABINET_GUIDS = [CABINET_GUID, CABINET_SDL_GUID]
const CABINET_MAPPING = CABINET_GUID + ",Spicy DragonRise Arcade," + \
	"a:b1,b:b0,x:b2,y:b3,guide:b4,leftshoulder:b5,back:b8,start:b9," + \
	"leftx:a0,lefty:a1,dpup:h0.1,dpright:h0.2,dpdown:h0.4,dpleft:h0.8,platform:Linux,"
# SDL's HID backend reorders this device relative to Linux's raw evdev/js
# indices. These bindings were measured on both cabinet controllers.
const CABINET_SDL_MAPPING = CABINET_SDL_GUID + ",Spicy DragonRise Arcade," + \
	"a:b1,b:b3,x:b0,y:b2,guide:b9,leftshoulder:b10,back:b4,start:b6," + \
	"leftx:a0,lefty:a1,dpup:h0.1,dpright:h0.2,dpdown:h0.4,dpleft:h0.8,platform:Linux,"

const RAW_BUTTONS = {
	0: JOY_BUTTON_B,             # Cabinet B: back / pause, never a live-game quit.
	1: JOY_BUTTON_A,             # Cabinet A: eat / use.
	2: JOY_BUTTON_X,             # Cabinet X: emergency heat.
	3: JOY_BUTTON_Y,             # Cabinet Y: discard.
	4: JOY_BUTTON_GUIDE,         # Coin: deliberately unbound.
	5: JOY_BUTTON_LEFT_SHOULDER, # P1/menu: pause / back.
	8: JOY_BUTTON_BACK,          # Select: pause / back.
	9: JOY_BUTTON_START,         # Start: confirm / pause / resume.
}
const RELEASE_ACTIONS = [
	"ui_accept", "ui_cancel", "arcade_pause",
	"ui_left", "ui_right", "ui_up", "ui_down",
	"ui_focus_next", "ui_focus_prev", "use", "emergency heat", "discard",
]


static func install() -> void:
	Input.add_joy_mapping(CABINET_MAPPING, true)
	Input.add_joy_mapping(CABINET_SDL_MAPPING, true)
	# Keep every existing keyboard binding. In menus Start, not a combat button,
	# confirms. Bind all devices (-1), so either cabinet slot can play this game.
	for action in ["ui_accept", "ui_cancel", "ui_left", "ui_right", "ui_up", "ui_down"]:
		for event in InputMap.action_get_events(action):
			if event is InputEventJoypadButton or event is InputEventJoypadMotion:
				InputMap.action_erase_event(action, event)
	_add_button("ui_accept", JOY_BUTTON_START)
	for button in [JOY_BUTTON_B, JOY_BUTTON_BACK, JOY_BUTTON_LEFT_SHOULDER]:
		_add_button("ui_cancel", button)
	_add_button("use", JOY_BUTTON_A)
	_add_button("emergency heat", JOY_BUTTON_X)
	_add_button("discard", JOY_BUTTON_Y)
	if not InputMap.has_action("arcade_pause"):
		InputMap.add_action("arcade_pause")
	var escape := InputEventKey.new()
	escape.physical_keycode = KEY_ESCAPE
	_add_event("arcade_pause", escape)
	for button in [JOY_BUTTON_START, JOY_BUTTON_BACK, JOY_BUTTON_LEFT_SHOULDER]:
		_add_button("arcade_pause", button)
	_add_direction("ui_left", JOY_BUTTON_DPAD_LEFT, JOY_AXIS_LEFT_X, -1.0)
	_add_direction("ui_right", JOY_BUTTON_DPAD_RIGHT, JOY_AXIS_LEFT_X, 1.0)
	_add_direction("ui_up", JOY_BUTTON_DPAD_UP, JOY_AXIS_LEFT_Y, -1.0)
	_add_direction("ui_down", JOY_BUTTON_DPAD_DOWN, JOY_AXIS_LEFT_Y, 1.0)
	# cheat_speed deliberately retains only its original keyboard P binding.


static func _add_direction(action: String, button: int, axis: int, value: float) -> void:
	InputMap.action_set_deadzone(action, 0.35)
	_add_button(action, button)
	var event := InputEventJoypadMotion.new()
	event.device = -1
	event.axis = axis
	event.axis_value = value
	_add_event(action, event)


static func _add_button(action: String, button: int) -> void:
	var event := InputEventJoypadButton.new()
	event.device = -1
	event.button_index = button
	_add_event(action, event)


static func _add_event(action: String, event: InputEvent) -> void:
	if not InputMap.action_has_event(action, event):
		InputMap.action_add_event(action, event)


static func is_neutral() -> bool:
	for action in RELEASE_ACTIONS:
		if Input.is_action_pressed(action):
			return false
	return not (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or
		Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT))


static func is_menu_event(event: InputEvent) -> bool:
	for action in RELEASE_ACTIONS:
		if event.is_action(action):
			return true
	return event is InputEventMouseButton


static func describe_device(device: int) -> Dictionary:
	return {
		"device": device,
		"name": Input.get_joy_name(device),
		"guid": Input.get_joy_guid(device),
		"known": Input.is_joy_known(device),
		"cabinet_mapping": Input.get_joy_guid(device) in CABINET_GUIDS,
		"info": Input.get_joy_info(device),
	}
