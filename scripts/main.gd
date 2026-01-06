extends Node2D

@export var player_scene: PackedScene
@export var levels: Array[PackedScene]
var current_level = 0
var level_instance: Level = null
var player: Player

func _ready() -> void:
	$TitleScreenSounds.play()

func next_level() -> void:
	$Transition.play_transition()
	goto_level(current_level + 1)

func goto_level(level: int) -> void:
	$Transition.play_transition()
	print("new level")
	current_level = level
	player.reset()
	if player.get_parent():
		player.get_parent().remove_child(player)
	level_instance = levels[current_level - 1].instantiate()
	level_instance.add_child(player)
	add_child(level_instance)
	player.spanw_in()
	if player.transmutation_copy:
		level_instance.transmute()
	$UpgradeScreen.hide()
	player.set_level_label(level)

func goto_upgrade() -> void:
	if level_instance:
		level_instance.remove_child(player)
		level_instance.queue_free()
	$UpgradeScreen.show()
	$UpgradeScreen.refresh()

func game_over():
	$BgMusic.stop()
	$Transition.play_transition()
	level_instance.queue_free()
	player = player_scene.instantiate()
	$GameOverScreen.show()
	$GameOverSound.play()

func to_title_screen():
	$TitleScreen.show()
	$TitleScreenSounds.play()
	$GameOverScreen.hide()
	$GameOverSound.stop()
	$WinScreen.hide()
	$WinSound.stop()
	$Compendium.hide()
	if level_instance:
		level_instance.queue_free()
	$BgMusic.stop()

func start_game(level = 1) -> void:
	$UpgradeScreen.reset()
	Stats.reset()
	player = player_scene.instantiate()
	$TitleScreen.hide()
	$BgMusic.play()
	$TitleScreenSounds.stop()
	goto_level(level)

func win():
	$BgMusic.stop()
	$Transition.play_transition()
	level_instance.queue_free()
	player = player_scene.instantiate()
	$WinScreen.show()
	
	$WinScreen.set_text()
	$WinSound.play()

func start_tutorial() -> void:
	start_game(11)


func _on_compendium_button_pressed() -> void:
	$Compendium.show()
	$TitleScreen.hide()


func _on_exit_button_pressed() -> void:
	get_tree().quit()
	#print((70000 / 1000) / 60)
