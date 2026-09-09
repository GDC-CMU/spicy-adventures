extends Node
## Bounded native-renderer fixture batch, not proof of physical cabinet play.
## --windowed res://tests/arcade_visual.tscn -- --arcade
## --spicy-arcade-captures=C:/.../spicy-arcade-visual

var game
var ui
var output := ""
var captures := 0
@onready var root: Window = get_tree().root


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--spicy-arcade-captures="):
			output = argument.trim_prefix("--spicy-arcade-captures=")
	_run.call_deferred()


func _wait() -> void:
	for i in range(20):
		await get_tree().process_frame


func _capture(label: String) -> void:
	await _wait()
	# The original dissolve is one second. Capture the settled game, not the
	# middle of its preserved transition (which darkens the scene).
	await get_tree().create_timer(1.05).timeout
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var destination := output.path_join("spicy-arcade-" + label + ".png")
	var error := image.save_png(destination)
	if error != OK:
		printerr("SPICY_ARCADE_CAPTURE_FAILED ", error, " ", destination)
		get_tree().quit(1)
		return
	captures += 1
	print("SPICY_ARCADE_CAPTURE ", destination, " window=", root.size,
		" rendered_content=", image.get_size(), " aspect=keep")


func _run() -> void:
	if DisplayServer.get_name() == "headless" or output.is_empty() or \
			not output.get_file().begins_with("spicy-arcade-"):
		printerr("Use a native display and an explicit spicy-arcade-* capture directory.")
		get_tree().quit(1)
		return
	DirAccess.make_dir_recursive_absolute(output)
	var ignore := FileAccess.open(output.path_join(".gdignore"), FileAccess.WRITE)
	ignore.close()
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(800, 600)
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	get_tree().current_scene = game
	ui = game.arcade_ui
	await _capture("800-title")
	ui.show_controls(false)
	await _capture("800-controls")
	game.start_game(11)
	await _capture("800-tutorial")
	game.to_title_screen()
	game._on_compendium_button_pressed()
	ui.show_entries(true)
	await _capture("800-peppers")
	ui.show_catalog()
	ui.show_entries(false)
	await _capture("800-enemies")
	game.to_title_screen()
	game.start_game()
	await _wait()
	await _capture("800-play")
	ui.show_pause()
	await _capture("800-pause")
	ui.resume_game()
	game.goto_upgrade()
	await _wait()
	await _capture("800-upgrades")
	game.to_title_screen()
	game.start_game()
	await _wait()
	game.win()
	await _wait()
	await _capture("800-results")
	game.to_title_screen()
	root.size = Vector2i(1280, 720)
	await _capture("1280-title")
	game.start_game(11)
	await _capture("1280-tutorial")
	print("SPICY_ARCADE_VISUAL_BATCH_COMPLETE captures=", captures,
		" renderer=", RenderingServer.get_current_rendering_method())
	game.to_title_screen()
	ui.show_exit_confirm()
	Arcade.request_exit()
