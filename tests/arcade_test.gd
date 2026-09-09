extends Node
## Real scenes and Input.parse_input_event; no external test framework.
## These are synthetic normalized slot-0/slot-1 events, NOT physical USB proof.

const Controls = preload("res://arcade/controls.gd")
const PEPPER = preload("res://peppers/indian_masala_chilli.tscn")

var game
var ui
var failures := 0
var checks := 0
var _expected_exit := false
var _started := 0
var _native_frame_times: Array[float] = []
@onready var root: Window = get_tree().root
var paused: bool:
	get:
		return get_tree().paused


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_started = Time.get_ticks_msec()
	_run.call_deferred()


func _process(_delta: float) -> void:
	if Time.get_ticks_msec() - _started > 150000:
		printerr("SPICY_ARCADE_TEST_TIMEOUT")
		quit(1)
	if DisplayServer.get_name() != "headless" and is_instance_valid(ui) and \
			ui.page == &"play" and not paused and not Arcade.guarded:
		_native_frame_times.append(_delta * 1000.0)


func quit(code: int) -> void:
	get_tree().quit(code)


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("SPICY_ARCADE_ASSERT_FAILED: ", message)
		quit(1)


func _frames(count := 3) -> void:
	for i in range(count):
		await get_tree().process_frame


func _ready_input() -> void:
	for i in range(240):
		if not Arcade.guarded:
			return
		await get_tree().process_frame
	_check(false, "release guard did not clear after neutral input")


func _joy(button: int, device: int, pressed: bool) -> void:
	var event := InputEventJoypadButton.new()
	event.device = device
	event.button_index = button
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _axis(axis: int, device: int, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = device
	event.axis = axis
	event.axis_value = value
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _key(keycode: int, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	event.keycode = keycode
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _tap(button: int, device := 0) -> void:
	await _ready_input()
	_joy(button, device, true)
	await _frames()
	_joy(button, device, false)
	await _frames()
	await _ready_input()


func _choose(index: int, device := 0) -> void:
	_check(index >= 0 and index < ui.buttons.size(), "menu target exists")
	for i in range(16):
		if root.gui_get_focus_owner() == ui.buttons[index]:
			await _tap(JOY_BUTTON_START, device)
			return
		await _tap(JOY_BUTTON_DPAD_DOWN, device)
	_check(false, "controller navigation could not reach menu item %d on %s" % [index, ui.page])


func _add_pepper() -> void:
	var vegetable = PEPPER.instantiate()
	game.level_instance.add_child(vegetable)
	game.player.get_node("Queue").push(vegetable)


func _check_layout() -> void:
	for label in ui.root_control.find_children("*", "Label", true, false):
		if not label.is_visible_in_tree():
			continue
		var rect: Rect2 = label.get_global_rect()
		_check(Rect2(0, 0, 1152, 648).encloses(rect), "label stays inside the original design canvas")
		if label.get_parent() is Button:
			_check(label.get_parent().get_global_rect().encloses(rect), "upgrade text stays inside its card")
		else:
			for button in ui.buttons:
				_check(not rect.intersects(button.get_global_rect()), "instruction text does not overlap a button")
	for icon in ui.root_control.find_children("*", "TextureRect", true, false):
		if icon.is_visible_in_tree() and icon.get_parent() is Button:
			_check(Rect2(Vector2.ZERO, icon.get_parent().size).encloses(Rect2(icon.position, icon.size)),
				"upgrade artwork stays inside its card")


func _run() -> void:
	Input.use_accumulated_input = false
	var version := Engine.get_version_info()
	_check(version.major == 4 and version.minor == 5 and version.patch == 2 and version.status == "stable",
		"pinned engine version")
	_check(ProjectSettings.get_setting("application/run/main_scene") == "uid://ds4vob4h38lsv",
		"original main-scene UID retained")
	_check(root.has_node("Stats") and root.has_node("Arcade"), "original Stats plus adapter autoload")
	_check(Arcade.enabled, "fixture explicitly enables arcade mode")
	Arcade.exit_requested.connect(_on_exit_requested)
	_test_mapping_contract()
	print("SPICY_ARCADE_TEST phase=startup")
	# Simulate a Start still held from the launcher while the original scene loads.
	_joy(JOY_BUTTON_START, 0, true)
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	get_tree().current_scene = game
	ui = game.arcade_ui
	await _frames(25)
	_check(ui.page == &"title", "held launcher Start does not auto-start")
	_joy(JOY_BUTTON_START, 0, false)
	await _ready_input()
	_check(root.content_scale_size == Vector2i(1152, 648), "original design canvas")
	_check(root.content_scale_aspect == Window.CONTENT_SCALE_ASPECT_KEEP, "uniform aspect scaling")
	_check(game.levels.size() == 11, "ten original levels and tutorial retained")
	_check(root.gui_get_focus_owner() == ui.buttons[0], "root initial focus")
	_check_layout()
	_joy(JOY_BUTTON_GUIDE, 0, true)
	Arcade.arm_release_guard()
	await _frames(25)
	_check(not Arcade.guarded and ui.page == &"title", "coin has no menu/guard side effect")
	_joy(JOY_BUTTON_GUIDE, 0, false)
	for device in [0, 1]:
		await _test_slot_lifecycle(device)
	print("SPICY_ARCADE_TEST phase=gameplay-upgrades")
	await _test_gameplay_and_upgrades()
	print("SPICY_ARCADE_TEST phase=compendium")
	await _test_compendium()
	print("SPICY_ARCADE_TEST phase=tutorial-results")
	await _test_tutorial_and_results()
	print("SPICY_ARCADE_TEST phase=keyboard-mouse-exit")
	await _test_keyboard_and_mouse()
	await _test_root_exit()


func _test_mapping_contract() -> void:
	_check(Controls.CABINET_GUID == "03000000790000000600000010010000", "exact Linux cabinet GUID")
	_check(Controls.CABINET_GUIDS.has("0300457e790000000600000010010000"),
		"Godot 4.5 SDL cabinet GUID with CRC is explicitly mapped")
	for field in ["a:b1", "b:b0", "x:b2", "y:b3", "guide:b4", "leftshoulder:b5",
			"back:b8", "start:b9", "leftx:a0", "lefty:a1", "platform:Linux"]:
		_check(field in Controls.CABINET_MAPPING.split(","), "explicit SDL mapping " + field)
	for field in ["a:b1", "b:b3", "x:b0", "y:b2", "guide:b9", "leftshoulder:b10",
			"back:b4", "start:b6", "leftx:a0", "lefty:a1", "platform:Linux"]:
		_check(field in Controls.CABINET_SDL_MAPPING.split(","),
			"measured Godot 4.5 HID mapping " + field)
	var expected := {0: 1, 1: 0, 2: 2, 3: 3, 4: 5, 5: 9, 8: 4, 9: 6}
	_check(Controls.RAW_BUTTONS == expected, "raw USB and Godot normalized indices are distinct")
	for pair in [["use", KEY_Z], ["emergency heat", KEY_A], ["discard", KEY_X], ["cheat_speed", KEY_P]]:
		var key := InputEventKey.new()
		key.physical_keycode = pair[1]
		_check(InputMap.action_has_event(pair[0], key), "keyboard binding preserved: " + pair[0])
	for event in InputMap.action_get_events("cheat_speed"):
		_check(not event is InputEventJoypadButton and not event is InputEventJoypadMotion,
			"no joystick cheat binding")
	for device in [0, 1]:
		for pair in [[JOY_BUTTON_A, "use"], [JOY_BUTTON_X, "emergency heat"],
				[JOY_BUTTON_Y, "discard"], [JOY_BUTTON_START, "ui_accept"],
				[JOY_BUTTON_B, "ui_cancel"], [JOY_BUTTON_BACK, "ui_cancel"],
				[JOY_BUTTON_LEFT_SHOULDER, "ui_cancel"]]:
			var event := InputEventJoypadButton.new()
			event.device = device
			event.button_index = pair[0]
			event.pressed = true
			_check(event.is_action_pressed(pair[1]), "normalized action in device slot %d: %s" % [device, pair[1]])
		var combat := InputEventJoypadButton.new()
		combat.device = device
		combat.button_index = JOY_BUTTON_A
		combat.pressed = true
		_check(not combat.is_action_pressed("ui_accept"), "combat A cannot confirm menus")


func _test_slot_lifecycle(device: int) -> void:
	print("SPICY_ARCADE_TEST synthetic_slot=", device)
	await _ready_input()
	_joy(JOY_BUTTON_START, device, true)
	await _frames(25)
	_check(ui.page == &"play" and game.current_level == 1, "slot Start begins a real run")
	_check(not paused, "new run is not paused")
	var player_id: int = game.player.get_instance_id()
	_add_pepper()
	_joy(JOY_BUTTON_A, device, true)
	await _frames(12)
	_check(game.player.get_node("Queue").vegetable_list.size() == 1,
		"held launch/combat inputs do not eat on entry")
	_joy(JOY_BUTTON_START, device, false)
	await _frames(20)
	_check(Arcade.guarded, "combat button must also release before run accepts input")
	_joy(JOY_BUTTON_A, device, false)
	await _ready_input()
	var original_position: Vector2 = game.player.position
	_axis(JOY_AXIS_LEFT_X, device, 1.0)
	await _frames(12)
	_axis(JOY_AXIS_LEFT_X, device, 0.0)
	_check(game.player.position.x > original_position.x, "left stick moves real player in each slot")
	_check(game.player.get_node("Camera2D").zoom == Vector2(0.75, 0.75), "original camera zoom")
	_check_layout()
	await _tap(JOY_BUTTON_A, device)
	_check(game.player.get_node("Queue").vegetable_list.is_empty() and game.player.heat > 0,
		"A eats a real pepper through the original queue/use method")
	_joy(JOY_BUTTON_B, device, true)
	await _frames(25)
	_check(ui.page == &"pause" and paused, "B pauses, not exits, a live game")
	var pause_position: Vector2 = game.player.position
	var pause_time: int = Stats.calculate()[3]
	await _frames(20)
	_check(ui.page == &"pause", "held B cannot cascade out of pause")
	_check(game.player.position == pause_position, "pause freezes world movement")
	_check(Stats.calculate()[3] == pause_time, "pause freezes elapsed run time")
	_joy(JOY_BUTTON_B, device, false)
	await _ready_input()
	await _tap(JOY_BUTTON_START, device)
	_check(ui.page == &"play" and not paused, "Start resumes exactly once")
	_check(game.player.get_instance_id() == player_id, "pause does not replace the player/run")
	for button in [JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_BACK, JOY_BUTTON_START]:
		await _tap(button, device)
		_check(ui.page == &"pause", "P1 / Select / Start pauses safely")
		await _tap(JOY_BUTTON_B, device)
		_check(ui.page == &"play", "B returns one level from pause")
	await _tap(JOY_BUTTON_B, device)
	await _choose(2, device)
	_check(ui.page == &"leave_confirm" and paused, "main menu requires an explicit run-leave confirmation")
	_check(root.gui_get_focus_owner() == ui.buttons[0], "destructive confirmation defaults to staying")
	await _tap(JOY_BUTTON_B, device)
	_check(ui.page == &"pause", "B cancels leaving the run")
	await _choose(2, device)
	await _choose(1, device)
	_check(ui.page == &"title" and not paused, "confirmed main-menu return unpauses tree")
	_check(game.player == null and game.level_instance == null, "run-owned nodes released")
	_check(root.canvas_transform == Transform2D.IDENTITY, "menu canvas is not stranded at player camera")


func _test_gameplay_and_upgrades() -> void:
	# Tutorial has a safe starting area; test normal action methods, not cheats.
	game.start_game(11)
	await _ready_input()
	var player = game.player
	player.effect_speed(2.0, 0.2)
	ui.show_pause()
	await get_tree().create_timer(0.35).timeout
	_check(player.speed_multiplier == 2.0, "timed player effects do not expire during pause")
	ui.resume_game()
	await get_tree().create_timer(0.3).timeout
	_check(player.speed_multiplier == 1.0, "timed effects resume at their original duration")
	await _ready_input()
	player.emergency_heat_unlocked = true
	player.available_emergency_heat = true
	player.can_discard = true
	player.heat = 0
	await _tap(JOY_BUTTON_X, 1)
	_check(player.heat > 90 and not player.available_emergency_heat, "X spends the unlocked emergency heat")
	player.heat = 40
	await _tap(JOY_BUTTON_X, 1)
	_check(player.heat < 40, "emergency heat cannot be reused in a level")
	_add_pepper()
	_add_pepper()
	await _tap(JOY_BUTTON_Y, 1)
	_check(player.get_node("Queue").vegetable_list.size() == 1, "Y discards one unlocked queue entry")
	_key(KEY_P, true)
	await _frames(4)
	_key(KEY_P, false)
	_check(player.speed == 500 and player.burn_multiplier == 1, "arcade keyboard P cannot enable debug damage/speed")
	game.to_title_screen()
	await _ready_input()
	await _tap(JOY_BUTTON_START)
	var run_player_id: int = game.player.get_instance_id()
	# Use the real level completion callback. No simulation/upgrade duplication.
	game.level_instance._on_win_zone_body_entered(game.player)
	await _frames()
	await _ready_input()
	_check(ui.page == &"upgrade" and game.level_instance == null, "real level completion opens upgrade offers")
	_check(game.player.get_parent() == null, "continuing player retained off-tree between levels")
	var offers = game.get_node("UpgradeScreen")
	_check(offers.on_screen.size() == 3, "three real random upgrade offers")
	_check_layout()
	await _tap(JOY_BUTTON_DPAD_RIGHT, 1)
	_check(offers.selected == offers.on_screen[1], "directional upgrade focus selects the actual offer")
	_joy(JOY_BUTTON_START, 1, true)
	await _frames(25)
	_check(ui.page == &"upgrade" and game.current_level == 1, "held selection Start cannot buy/advance")
	_check(root.gui_get_focus_owner() == ui.buttons[3], "selection moves to explicit purchase confirmation")
	_joy(JOY_BUTTON_START, 1, false)
	await _ready_input()
	await _tap(JOY_BUTTON_START, 1)
	_check(ui.page == &"play" and game.current_level == 2, "confirmed upgrade advances exactly one level")
	_check(game.player.get_instance_id() == run_player_id, "upgrade preserves the real continuing player")
	_check(offers.on_screen.is_empty(), "old offers detached after purchase")
	# A pause during upgrade must neither reroll nor lose the selected upgrades.
	game.level_instance._on_win_zone_body_entered(game.player)
	await _frames()
	await _ready_input()
	var offer_ids: Array[int] = []
	for offer in offers.on_screen:
		offer_ids.append(offer.get_instance_id())
	await _tap(JOY_BUTTON_DPAD_RIGHT, 1)
	var selected_before_pause = offers.selected
	await _tap(JOY_BUTTON_LEFT_SHOULDER, 1)
	_check(paused and ui.page == &"pause", "upgrade screen has a pause/menu path")
	await _tap(JOY_BUTTON_B, 1)
	var after_ids: Array[int] = []
	for offer in offers.on_screen:
		after_ids.append(offer.get_instance_id())
	_check(after_ids == offer_ids and ui.page == &"upgrade", "resume does not reroll upgrades")
	_check(offers.selected == selected_before_pause, "upgrade pause/resume also preserves selected focus")
	game.to_title_screen()
	await _ready_input()
	_check(offers.upgrade_list.size() == offers.original.size() and offers.on_screen.is_empty(),
		"new run restores the full upgrade pool after abandonment")


func _test_compendium() -> void:
	await _choose(2, 1)
	_check(ui.page == &"catalog", "controller opens compendium from root")
	await _choose(0, 1)
	_check(ui.page == &"peppers" and ui.buttons.size() == 7, "all six peppers plus back are focusable")
	_check_layout()
	for i in range(6):
		_check(not ui.description.text.is_empty(), "pepper focus shows original description")
		await _tap(JOY_BUTTON_START, 1)
		await _tap(JOY_BUTTON_DPAD_DOWN, 1)
	await _tap(JOY_BUTTON_B, 1)
	_check(ui.page == &"catalog", "B returns from pepper details to categories")
	await _choose(1, 1)
	_check(ui.page == &"enemies" and ui.buttons.size() == 8, "all seven enemies plus back are focusable")
	_check_layout()
	for i in range(7):
		_check(not ui.description.text.is_empty(), "enemy focus shows original description")
		await _tap(JOY_BUTTON_START, 1)
		await _tap(JOY_BUTTON_DPAD_DOWN, 1)
	await _tap(JOY_BUTTON_B, 1)
	await _tap(JOY_BUTTON_B, 1)
	_check(ui.page == &"title", "compendium back returns to root without quitting")


func _test_tutorial_and_results() -> void:
	await _choose(1)
	_check(ui.page == &"controls", "controller tutorial introduction")
	_check_layout()
	await _choose(0)
	_check(ui.page == &"play" and game.current_level == 11, "tutorial launches its original level")
	_check_layout()
	_check(is_instance_valid(ui.tutorial_hint), "controller-readable tutorial guidance")
	_check(game.level_instance.get_node("IndianMasalaChilli").position.x == 838,
		"tutorial world coordinates preserved")
	for x in [0, 850, 1700, 2400]:
		game.player.position.x = x
		await _frames()
		_check(not ui.tutorial_hint.text.is_empty(), "each tutorial stage has readable instructions")
	game.level_instance._on_win_zone_body_entered(game.player)
	await _frames()
	await _ready_input()
	_check(ui.page == &"title" and game.level_instance == null, "tutorial exit reaches main menu, not level twelve")
	await _tap(JOY_BUTTON_START)
	game.player.take_damage(100)
	await _frames()
	await _ready_input()
	_check(ui.page == &"result" and game.player == null, "real player death reaches results and releases the run")
	var result_time: int = Stats.calculate()[3]
	await _frames(20)
	_check(Stats.calculate()[3] == result_time, "result time is frozen")
	await _choose(0, 1)
	_check(ui.page == &"play" and game.current_level == 1 and game.player.health == game.player.max_health,
		"controller retry creates a fresh real run")
	game.win()
	await _frames()
	await _ready_input()
	_check(ui.page == &"result" and game.get_node("WinScreen").visible, "original win handler has controller results")
	await _tap(JOY_BUTTON_B, 1)
	_check(ui.page == &"title", "B from win results returns to root")


func _test_keyboard_and_mouse() -> void:
	await _ready_input()
	_key(KEY_ENTER, true)
	await _frames()
	_key(KEY_ENTER, false)
	await _ready_input()
	_check(ui.page == &"play", "keyboard Enter starts game")
	_add_pepper()
	_key(KEY_Z, true)
	await _frames(4)
	_key(KEY_Z, false)
	_check(game.player.get_node("Queue").vegetable_list.is_empty(), "original keyboard Z eats")
	_key(KEY_ESCAPE, true)
	await _frames(4)
	_key(KEY_ESCAPE, false)
	await _ready_input()
	_check(ui.page == &"pause", "keyboard Escape pauses")
	# Real GUI mouse coordinates, not direct handler invocation.
	# The dummy display is only 64×64; convert logical canvas to window pixels,
	# exactly as a real letterboxed 800×600 window would require.
	var target: Vector2 = root.get_final_transform() * (
		ui.buttons[0].get_global_transform_with_canvas() * (ui.buttons[0].size * 0.5))
	var motion := InputEventMouseMotion.new()
	motion.position = target
	motion.global_position = target
	Input.parse_input_event(motion)
	Input.flush_buffered_events()
	await _frames()
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
		event.position = target
		event.global_position = target
		event.pressed = pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		await _frames()
	await _ready_input()
	_check(ui.page == &"play", "mouse still activates the visible Resume button")
	game.to_title_screen()
	await _ready_input()


func _test_root_exit() -> void:
	_joy(JOY_BUTTON_B, 1, true)
	await _frames(30)
	_check(ui.page == &"exit_confirm", "root B opens, but does not accept, exit confirmation")
	_check(root.gui_get_focus_owner() == ui.buttons[0], "root exit defaults to staying")
	_joy(JOY_BUTTON_B, 1, false)
	await _ready_input()
	await _tap(JOY_BUTTON_B, 1)
	_check(ui.page == &"title", "fresh B cancels root exit")
	await _choose(3, 1)
	_check(ui.page == &"exit_confirm", "root exit button also requires confirmation")
	# Last action must really take the game's normal quit(0) path.
	await _tap(JOY_BUTTON_DPAD_DOWN, 1)
	_check(root.gui_get_focus_owner() == ui.buttons[1], "explicit exit is focused")
	_expected_exit = true
	_joy(JOY_BUTTON_START, 1, true)


func _on_exit_requested(code: int) -> void:
	if not _expected_exit or code != 0 or failures != 0:
		printerr("SPICY_ARCADE_UNEXPECTED_EXIT code=", code, " failures=", failures)
		return
	if not _native_frame_times.is_empty():
		_native_frame_times.sort()
		var count := _native_frame_times.size()
		print("SPICY_ARCADE_NATIVE_FRAME_TIMES samples=", count,
			" p50_ms=", snappedf(_native_frame_times[count / 2], 0.01),
			" p95_ms=", snappedf(_native_frame_times[mini(count - 1, int(count * 0.95))], 0.01),
			" max_ms=", snappedf(_native_frame_times.back(), 0.01),
			" renderer=", RenderingServer.get_current_rendering_method())
	print("SPICY_ARCADE_TESTS_PASSED checks=", checks, " synthetic_slots=0,1 normal_exit=0")
