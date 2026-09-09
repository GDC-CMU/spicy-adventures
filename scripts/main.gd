extends Node2D

@export var player_scene: PackedScene
@export var levels: Array[PackedScene]
var current_level = 0
var level_instance: Level = null
var player: Player
var screen: StringName = &"title"
var last_start_level = 1
var arcade_ui

func _ready() -> void:
	arcade_ui = Arcade.attach_game(self)
	$TitleScreenSounds.play()
	arcade_ui.show_title()

func next_level() -> void:
	goto_level(current_level + 1)

func goto_level(level: int) -> void:
	if level < 1 or level > levels.size() or not is_instance_valid(player):
		return
	$Transition.play_transition()
	current_level = level
	player.reset()
	_release_level(true)
	level_instance = levels[current_level - 1].instantiate()
	level_instance.add_child(player)
	add_child(level_instance)
	player.get_node("Camera2D").enabled = true
	player.spanw_in()
	if player.transmutation_copy:
		level_instance.transmute()
	$UpgradeScreen.hide()
	player.set_level_label(level)
	screen = &"play"
	Stats.resume_run()
	arcade_ui.show_play()

func goto_upgrade() -> void:
	if screen != &"play":
		return
	screen = &"upgrade"
	level_instance.process_mode = Node.PROCESS_MODE_DISABLED
	Stats.pause_run()
	_finish_upgrade.call_deferred()

func _finish_upgrade() -> void:
	if screen != &"upgrade":
		return
	_release_level(true)
	$UpgradeScreen.show()
	$UpgradeScreen.refresh()
	arcade_ui.show_upgrade()

func game_over():
	if screen != &"play":
		return
	screen = &"result"
	level_instance.process_mode = Node.PROCESS_MODE_DISABLED
	Stats.pause_run()
	_finish_result.call_deferred(false)

func _finish_result(won: bool) -> void:
	if screen != &"result":
		return
	$BgMusic.stop()
	$Transition.play_transition()
	_release_level()
	if won:
		$WinScreen.show()
		$WinScreen.set_text()
		$WinSound.play()
	else:
		$GameOverScreen.show()
		$GameOverSound.play()
	arcade_ui.show_result(won)

func to_title_screen():
	screen = &"title"
	get_tree().paused = false
	Stats.pause_run()
	_release_level()
	$UpgradeScreen.reset()
	$UpgradeScreen.hide()
	$TitleScreen.show()
	$TitleScreenSounds.play()
	$GameOverScreen.hide()
	$GameOverSound.stop()
	$WinScreen.hide()
	$WinSound.stop()
	$Compendium.hide()
	$Compendium.back_to_compendium()
	$BgMusic.stop()
	arcade_ui.show_title()

func start_game(level = 1) -> void:
	if level < 1 or level > levels.size():
		return
	get_tree().paused = false
	_release_level()
	last_start_level = level
	$UpgradeScreen.reset()
	Stats.reset()
	player = player_scene.instantiate()
	$TitleScreen.hide()
	$GameOverScreen.hide()
	$GameOverSound.stop()
	$WinScreen.hide()
	$WinSound.stop()
	$Compendium.hide()
	$BgMusic.play()
	$TitleScreenSounds.stop()
	goto_level(level)

func retry_game() -> void:
	start_game(last_start_level)

func win():
	if screen != &"play":
		return
	screen = &"result"
	level_instance.process_mode = Node.PROCESS_MODE_DISABLED
	Stats.pause_run()
	_finish_result.call_deferred(true)

func _release_level(keep_player := false) -> void:
	if is_instance_valid(player):
		player.get_node("Camera2D").enabled = false
		if player.get_parent():
			player.get_parent().remove_child(player)
		if not keep_player:
			player.queue_free()
			player = null
	if is_instance_valid(level_instance):
		if level_instance.get_parent():
			level_instance.get_parent().remove_child(level_instance)
		level_instance.queue_free()
	level_instance = null
	# A removed Camera2D otherwise leaves the menus at the last world position.
	get_viewport().canvas_transform = Transform2D.IDENTITY

func start_tutorial() -> void:
	start_game(11)


func _on_compendium_button_pressed() -> void:
	screen = &"catalog"
	$Compendium.show()
	$TitleScreen.hide()
	arcade_ui.show_catalog()


func _on_exit_button_pressed() -> void:
	Arcade.request_exit()

func stop_audio() -> void:
	for node in find_children("*", "", true, false):
		if node is AudioStreamPlayer or node is AudioStreamPlayer2D:
			node.stop()

func _exit_tree() -> void:
	stop_audio()
	# At an upgrade screen the continuing player is intentionally off-tree.
	if is_instance_valid(player) and player.get_parent() == null:
		player.free()
