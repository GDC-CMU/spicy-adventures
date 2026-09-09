extends Node
## Presentation/input adapter only. The original Main/Level/Player own gameplay.

signal exit_requested(code: int)

const Controls = preload("res://arcade/controls.gd")
const Menu = preload("res://arcade/menu.gd")
const DESIGN_SIZE = Vector2i(1152, 648)

var enabled := false
var game_data_dir := ""
var menu: CanvasLayer
var guarded := true
var _exiting := false
var _neutral_frames := 0
var _guard_time := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	enabled = OS.get_environment("ARCADE_MODE") == "1" or \
		OS.get_cmdline_user_args().has("--arcade") or OS.has_feature("arcade")
	# There are no persistent gameplay saves in the original project. Do not
	# create/reset a save, or put fixture output in the launcher's data directory.
	game_data_dir = OS.get_environment("ARCADE_GAME_DATA_DIR")
	Controls.install()
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	var window := get_window()
	window.content_scale_size = DESIGN_SIZE
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	if enabled and not OS.has_feature("web") and DisplayServer.get_name() != "headless":
		if not OS.get_cmdline_args().has("--windowed"):
			window.mode = Window.MODE_FULLSCREEN
	get_tree().auto_accept_quit = false
	arm_release_guard()
	if OS.get_cmdline_user_args().has("--arcade-controller-log"):
		for device in Input.get_connected_joypads():
			print("SPICY_ARCADE_CONTROLLER ", JSON.stringify(Controls.describe_device(device)))


func attach_game(game: Node2D) -> CanvasLayer:
	if is_instance_valid(menu):
		menu.queue_free()
	menu = Menu.new()
	menu.game = game
	game.add_child(menu)
	return menu


func arm_release_guard() -> void:
	guarded = true
	_neutral_frames = 0
	_guard_time = 0.0


func _process(delta: float) -> void:
	if not guarded:
		return
	_guard_time += delta
	if Controls.is_neutral():
		_neutral_frames += 1
	else:
		_neutral_frames = 0
	# A held Start/B/axis must be released, not just timed out. Two neutral frames
	# also prevent the transition's just-pressed action reaching the new scene.
	if _neutral_frames >= 2 and _guard_time >= 0.12:
		guarded = false


func gameplay_input_allowed() -> bool:
	return not guarded and not get_tree().paused and \
		is_instance_valid(menu) and menu.page == &"play"


func request_exit() -> void:
	# Only an explicit confirmation at the root can close the native process.
	if _exiting or not is_instance_valid(menu) or menu.page != &"exit_confirm":
		return
	_exiting = true
	arm_release_guard()
	menu.game.stop_audio()
	# Let the audio server drain its stop commands before quitting. In particular,
	# the original embedded title MP3 must not leave a playback alive at shutdown.
	await get_tree().create_timer(0.08).timeout
	exit_requested.emit(0)
	get_tree().quit(0)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and is_instance_valid(menu):
		menu.back()


func _on_joy_connection_changed(device: int, connected: bool) -> void:
	arm_release_guard()
	if OS.get_cmdline_user_args().has("--arcade-controller-log"):
		if connected:
			print("SPICY_ARCADE_CONTROLLER ", JSON.stringify(Controls.describe_device(device)))
		else:
			print("SPICY_ARCADE_CONTROLLER disconnected device=", device)
	if is_instance_valid(menu) and menu.page == &"play" and not connected:
		menu.show_pause()
