extends SceneTree
## External fixture bootstrap for a prepared PCK / native export.
## Delay loading the Node fixture until the pack's real autoloads exist.
## This script is not included in the production Linux Arcade pack.


func _initialize() -> void:
	_start.call_deferred()


func _start() -> void:
	var path := ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--spicy-arcade-fixture="):
			path = argument.trim_prefix("--spicy-arcade-fixture=").replace("\\", "/")
	if path.is_empty() or not path.is_absolute_path() or not FileAccess.file_exists(path):
		printerr("An existing absolute --spicy-arcade-fixture=PATH is required.")
		quit(1)
		return
	var script := load(path) as Script
	if script == null or not script.can_instantiate():
		printerr("Cannot load Spicy Adventure fixture: ", path)
		quit(1)
		return
	var fixture := Node.new()
	fixture.set_script(script)
	root.add_child(fixture)
