extends CanvasLayer
## Accessible controls over the original art. No replacement gameplay scene.

const Look = preload("res://arcade/look.gd")
const Controls = preload("res://arcade/controls.gd")

var game
var page: StringName = &"title"
var buttons: Array[Button] = []
var root_control: Control
var description: RichTextLabel
var tutorial_hint: Label
var _body: Control
var _confirm: Button
var _resume_page: StringName = &"play"
var _help_from_pause := false
var _nav_direction := Vector2i.ZERO
var _nav_timer := 0.0


func _ready() -> void:
	name = "ArcadeMenu"
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	root_control = Control.new()
	root_control.name = "Interface"
	root_control.size = Vector2(1152, 648)
	root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.theme = Look.create_theme()
	add_child(root_control)
	# The old invisible buttons were behind the artwork. Replace only their
	# interaction surfaces; keep the art and their real game handlers.
	for button in game.find_children("*", "BaseButton", true, false):
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.hide()
	game.get_node("WinScreen/RichTextLabel").hide()


func _frame(next_page: StringName, dim := false) -> void:
	get_viewport().gui_release_focus()
	if is_instance_valid(_body):
		_body.hide()
		_body.queue_free()
	buttons.clear()
	description = null
	tutorial_hint = null
	_confirm = null
	page = next_page
	_nav_direction = Vector2i.ZERO
	_nav_timer = 0.0
	_body = Control.new()
	_body.name = String(next_page)
	_body.size = root_control.size
	_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.add_child(_body)
	if dim:
		var shade := ColorRect.new()
		shade.color = Color(0.02, 0.04, 0.08, 0.78)
		shade.size = root_control.size
		shade.mouse_filter = Control.MOUSE_FILTER_STOP
		_body.add_child(shade)
	Arcade.arm_release_guard()


func _panel(rect: Rect2) -> Panel:
	var panel := Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	_body.add_child(panel)
	return panel


func _label(text: String, rect: Rect2, font_size := 28) -> Label:
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.text = text
	label.position = rect.position
	label.size = rect.size
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_body.add_child(label)
	return label


func _button(text: String, rect: Rect2, action: Callable, art_only := false) -> Button:
	var button := Button.new()
	button.text = text
	button.tooltip_text = text
	button.accessibility_name = text
	button.position = rect.position
	button.size = rect.size
	button.focus_mode = Control.FOCUS_ALL
	button.pressed.connect(_activate.bind(action))
	# Hover can highlight, but must not steal controller focus when a new page
	# appears underneath a stationary mouse pointer. Clicking still takes focus.
	if art_only:
		button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		var hover := Look.panel_style()
		hover.draw_center = false
		hover.border_color = Look.ICE
		button.add_theme_stylebox_override("hover", hover)
		button.add_theme_stylebox_override("pressed", hover)
	_body.add_child(button)
	buttons.append(button)
	return button


func _activate(action: Callable) -> void:
	if not Arcade.guarded:
		action.call()


func _vertical_focus() -> void:
	for i in range(buttons.size()):
		var previous := buttons[posmod(i - 1, buttons.size())].get_path()
		var next := buttons[(i + 1) % buttons.size()].get_path()
		buttons[i].focus_neighbor_top = previous
		buttons[i].focus_neighbor_left = previous
		buttons[i].focus_neighbor_bottom = next
		buttons[i].focus_neighbor_right = next
		buttons[i].focus_previous = previous
		buttons[i].focus_next = next
	if not buttons.is_empty():
		buttons[0].grab_focus()


func _footer(text := "Stick / arrows: choose     Start / Enter: confirm     B / Esc: back") -> void:
	_panel(Rect2(20, 596, 1112, 42))
	_label(text, Rect2(34, 599, 1084, 36), 24)


func show_title() -> void:
	_frame(&"title")
	_panel(Rect2(790, 328, 344, 306))
	_button("New game", Rect2(806, 344, 312, 58), game.start_game)
	_button("How to play", Rect2(806, 414, 312, 58), show_controls.bind(false))
	_button("Compendium", Rect2(806, 484, 312, 58), game._on_compendium_button_pressed)
	_button("Exit to gallery" if Arcade.enabled else "Quit game",
		Rect2(806, 554, 312, 58), show_exit_confirm)
	_panel(Rect2(22, 551, 744, 83))
	_label("Stick / arrows: choose   •   Start / Enter: confirm\nB / Esc: back   •   Either controller can play",
		Rect2(38, 559, 712, 68), 26)
	_vertical_focus()


func show_play() -> void:
	_frame(&"play")
	var pause_button := _button("Pause  •  B / P1", Rect2(16, 12, 248, 50), show_pause)
	pause_button.focus_mode = Control.FOCUS_NONE
	_panel(Rect2(685, 12, 451, 78))
	_label("A / Z: eat   •   X: heat   •   Y: discard\nHeat / discard need upgrades",
		Rect2(699, 18, 421, 66), 24)
	game.player.get_node("GiveUpButton").hide()
	if game.current_level == 11:
		for node_name in ["RichTextLabel", "RichTextLabel2", "RichTextLabel3", "RichTextLabel4"]:
			game.level_instance.get_node(node_name).hide()
		_panel(Rect2(282, 108, 588, 116))
		tutorial_hint = _label("", Rect2(298, 116, 556, 100), 28)
		_update_tutorial()


func show_controls(from_pause := false) -> void:
	_help_from_pause = from_pause
	_frame(&"controls", true)
	_panel(Rect2(122, 44, 908, 534))
	_label("How to play", Rect2(156, 62, 840, 50), 40)
	_label("Collect peppers. Eat the oldest one to breathe fire.\nFace enemies by moving. Reach the green zone to advance.",
		Rect2(156, 122, 840, 88), 28)
	var names := ["Move", "Eat", "Heat", "Discard"]
	var bindings := ["Stick / arrow keys", "A / keyboard Z",
		"X / keyboard A  (requires upgrade)", "Y / keyboard X  (requires upgrade)"]
	for i in range(4):
		_label(names[i], Rect2(156, 226 + 41 * i, 168, 36), 28)
		_label(bindings[i], Rect2(348, 226 + 41 * i, 648, 36), 28)
	_label("Start / Enter / Space: confirm\nB / Esc / P1 / Select: pause or back", Rect2(156, 402, 840, 62), 26)
	if from_pause:
		_button("Back to pause", Rect2(350, 490, 452, 62), _render_pause)
	else:
		_button("Enter tutorial", Rect2(190, 490, 360, 62), game.start_tutorial)
		_button("Main menu", Rect2(602, 490, 360, 62), game.to_title_screen)
	_footer()
	_vertical_focus()


func _update_tutorial() -> void:
	if not is_instance_valid(tutorial_hint) or not is_instance_valid(game.player):
		return
	var x: float = game.player.position.x
	if x < 600:
		tutorial_hint.text = "1 / 4  •  Move with the stick or arrows.\nHead right to collect your first pepper."
	elif x < 1350:
		tutorial_hint.text = "2 / 4  •  Touch the pepper to collect it.\nPress A / Z to eat. Red bar = heat."
	elif x < 2150:
		tutorial_hint.text = "3 / 4  •  Trees grow more peppers.\nFace right and breathe fire to burn the wall."
	else:
		tutorial_hint.text = "4 / 4  •  Burn enemies and keep moving right.\nReach the green zone to return to the menu."


func show_catalog() -> void:
	game.get_node("Compendium").back_to_compendium()
	_frame(&"catalog")
	var peppers := _button("", Rect2(62, 235, 494, 278), show_entries.bind(true), true)
	peppers.tooltip_text = "Peppers"
	peppers.accessibility_name = "Peppers"
	var enemies := _button("", Rect2(600, 235, 494, 278), show_entries.bind(false), true)
	enemies.tooltip_text = "Enemies"
	enemies.accessibility_name = "Enemies"
	var back_button := _button("", Rect2(61, 529, 224, 91), game.to_title_screen, true)
	back_button.tooltip_text = "Main menu"
	back_button.accessibility_name = "Main menu"
	_panel(Rect2(318, 548, 802, 76))
	_label("Stick: choose   •   Start: open   •   B: main menu",
		Rect2(334, 558, 770, 56), 26)
	_vertical_focus()


func show_entries(peppers: bool) -> void:
	var catalog = game.get_node("Compendium")
	if peppers:
		catalog._on_peppers_button_pressed()
	else:
		catalog._on_button_pressed()
	_frame(&"peppers" if peppers else &"enemies")
	var content = catalog.get_node("PepperCompendium" if peppers else "EnemyCompendium")
	var entries: Array[Node] = []
	for entry in content.get_children():
		if entry.has_method("_on_button_pressed") and entry.has_node("Button"):
			entries.append(entry)
	entries.sort_custom(_entry_order)
	content.get_node("Description").hide()
	_panel(Rect2(20, 20, 482, 520))
	_label("Peppers" if peppers else "Enemies", Rect2(38, 26, 446, 50), 36)
	_panel(Rect2(542, 346, 590, 236))
	description = RichTextLabel.new()
	description.name = "EntryDescription"
	description.position = Vector2(558, 358)
	description.size = Vector2(558, 212)
	description.mouse_filter = Control.MOUSE_FILTER_STOP
	description.bbcode_enabled = false
	description.scroll_active = true
	description.focus_mode = Control.FOCUS_NONE
	_body.add_child(description)
	for i in range(entries.size()):
		var entry = entries[i]
		entry.hide()
		var text: String = entry.description
		var button := _button(text.get_slice("\n", 0), Rect2(34, 85 + i * 63, 454, 57),
			_select_entry.bind(entry))
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 46)
		var sprite = entry.vegetable.get_node_or_null("Sprite2D") if peppers else entry.get_node("Enemy")
		if sprite is Sprite2D:
			button.icon = sprite.texture
		button.focus_entered.connect(_select_entry.bind(entry))
	_button("Back to categories", Rect2(26, 552, 324, 70), show_catalog)
	_panel(Rect2(364, 591, 768, 47))
	_label("Stick: browse   •   X / Y: scroll   •   B: back",
		Rect2(380, 596, 736, 36), 24)
	_vertical_focus()


func _entry_order(a: Node2D, b: Node2D) -> bool:
	if absf(a.position.y - b.position.y) < 20:
		return a.position.x < b.position.x
	return a.position.y < b.position.y


func _select_entry(entry: Node) -> void:
	entry._on_button_pressed()
	description.text = entry.description.replace("\n\n", "\n")
	description.scroll_to_line(0)


func show_upgrade() -> void:
	_frame(&"upgrade")
	_label("Stick: choose   •   Start: select, then confirm   •   B / P1: pause",
		Rect2(98, 123, 980, 46), 26)
	var offers = game.get_node("UpgradeScreen")
	var previous_offer = offers.selected
	for i in range(offers.on_screen.size()):
		var offer: Upgrade = offers.on_screen[i]
		offer.hide()
		var card := _button("", Rect2(46 + 358 * i, 184, 344, 350), _offer_chosen.bind(offer))
		card.clip_contents = true
		card.tooltip_text = _upgrade_text(offer)
		card.accessibility_name = card.tooltip_text
		card.focus_entered.connect(_offer_focused.bind(offer, card))
		var icon := TextureRect.new()
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = offer.get_node("Sprite2D").texture
		icon.position = Vector2(80, 8)
		icon.size = Vector2(184, 156)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(icon)
		var text := Label.new()
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.add_theme_font_size_override("font_size", 28)
		text.text = card.tooltip_text
		text.position = Vector2(18, 170)
		text.size = Vector2(308, 164)
		text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		text.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(text)
	_confirm = _button("Take selected upgrade", Rect2(364, 553, 424, 70), offers.confirm)
	_vertical_focus()
	var count: int = offers.on_screen.size()
	for i in range(count):
		buttons[i].focus_neighbor_left = buttons[posmod(i - 1, count)].get_path()
		buttons[i].focus_neighbor_right = buttons[(i + 1) % count].get_path()
		buttons[i].focus_neighbor_top = _confirm.get_path()
		buttons[i].focus_neighbor_bottom = _confirm.get_path()
	if previous_offer in offers.on_screen:
		buttons[offers.on_screen.find(previous_offer)].grab_focus()


func _upgrade_text(offer: Upgrade) -> String:
	var text: String = offer.get_node("RichTextLabel").text
	# Only adapt displayed key hints, never the original upgrade effect or art.
	if text.begins_with("Press 'A'"):
		return "X / keyboard A: +100 heat.\nOnce per level."
	if text.begins_with("Press 'X'"):
		return "Y / keyboard X: discard the next pepper."
	return text


func _offer_focused(offer: Upgrade, card: Button) -> void:
	offer.select()
	if is_instance_valid(_confirm):
		for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
			_confirm.set_focus_neighbor(side, card.get_path())


func _offer_chosen(offer: Upgrade) -> void:
	offer.select()
	_confirm.grab_focus()
	Arcade.arm_release_guard()


func show_result(won: bool) -> void:
	_frame(&"result")
	_panel(Rect2(242, 178, 668, 432))
	_label("Ice King defeated!" if won else "Run over", Rect2(278, 194, 596, 60), 40)
	var values: Array[int] = Stats.calculate()
	var seconds: int = values[3] / 1000
	var summary := "Enemies defeated: %d\nHealth lost: %d   •   Best burn: %d\nTime: %d:%02d" % [
		values[0], values[1], values[2], seconds / 60, seconds % 60]
	_label(summary, Rect2(278, 272, 596, 144), 30)
	_button("Retry", Rect2(278, 470, 278, 64), game.retry_game)
	_button("Main menu", Rect2(592, 470, 282, 64), game.to_title_screen)
	_label("Start / Enter: confirm   •   B / Esc: main menu", Rect2(274, 552, 604, 42), 24)
	_vertical_focus()


func show_pause() -> void:
	if page not in [&"play", &"upgrade"]:
		return
	_resume_page = page
	get_tree().paused = true
	Stats.pause_run()
	_render_pause()


func _render_pause() -> void:
	_frame(&"pause", true)
	_panel(Rect2(306, 128, 540, 420))
	_label("Paused", Rect2(342, 144, 468, 54), 40)
	_label("Your run is frozen.", Rect2(342, 202, 468, 42), 28)
	_button("Resume", Rect2(342, 266, 468, 64), resume_game)
	_button("Controls", Rect2(342, 348, 468, 64), show_controls.bind(true))
	_button("Main menu", Rect2(342, 430, 468, 64), show_leave_confirm)
	_footer("Start / Enter: confirm     B / P1 / Esc: resume     No live-game quit shortcut")
	_vertical_focus()


func resume_game() -> void:
	get_tree().paused = false
	if game.screen == &"play":
		Stats.resume_run()
	if _resume_page == &"upgrade":
		show_upgrade()
	else:
		show_play()


func show_leave_confirm() -> void:
	_frame(&"leave_confirm", true)
	_panel(Rect2(256, 154, 640, 358))
	_label("Leave this run?", Rect2(292, 174, 568, 60), 40)
	_label("Return to the main menu and reset this run's upgrades.", Rect2(292, 250, 568, 100), 30)
	_button("Keep playing", Rect2(292, 388, 270, 66), _render_pause)
	_button("Main menu", Rect2(590, 388, 270, 66), game.to_title_screen)
	_footer()
	_vertical_focus()


func show_exit_confirm() -> void:
	_frame(&"exit_confirm", true)
	_panel(Rect2(256, 154, 640, 358))
	_label("Return to gallery?" if Arcade.enabled else "Quit game?",
		Rect2(292, 174, 568, 60), 40)
	_label("Close Spicy Adventure.", Rect2(292, 250, 568, 80), 30)
	_button("Stay here", Rect2(292, 388, 270, 66), show_title)
	_button("Exit game", Rect2(590, 388, 270, 66), Arcade.request_exit)
	_footer("Start / Enter: confirm     B / Esc: cancel     Exit returns to the launcher")
	_vertical_focus()


func back() -> void:
	if Arcade.guarded:
		return
	match page:
		&"play", &"upgrade":
			show_pause()
		&"pause":
			resume_game()
		&"leave_confirm":
			_render_pause()
		&"controls":
			if _help_from_pause:
				_render_pause()
			else:
				game.to_title_screen()
		&"peppers", &"enemies":
			show_catalog()
		&"catalog", &"result":
			game.to_title_screen()
		&"exit_confirm":
			show_title()
		&"title":
			show_exit_confirm()


func _input(event: InputEvent) -> void:
	if Arcade.guarded or event.is_echo():
		if Controls.is_menu_event(event):
			get_viewport().set_input_as_handled()
		return
	if page == &"play":
		if event.is_action_pressed("ui_cancel") or event.is_action_pressed("arcade_pause"):
			get_viewport().set_input_as_handled()
			show_pause()
		return
	if event.is_action("ui_accept"):
		get_viewport().set_input_as_handled()
		if event.is_action_pressed("ui_accept"):
			var focused := get_viewport().gui_get_focus_owner()
			if focused is Button and focused in buttons:
				focused.pressed.emit()
	elif event.is_action("ui_cancel") or event.is_action("arcade_pause"):
		get_viewport().set_input_as_handled()
		if event.is_pressed():
			back()
	elif event.is_action_pressed("ui_focus_next"):
		get_viewport().set_input_as_handled()
		_step_focus(1)
	elif event.is_action_pressed("ui_focus_prev"):
		get_viewport().set_input_as_handled()
		_step_focus(-1)
	elif Controls.is_menu_event(event) and not event is InputEventMouseButton:
		# Navigation repeats below are bounded, independent of OS key repeat.
		get_viewport().set_input_as_handled()


func _step_focus(step: int) -> void:
	var index := buttons.find(get_viewport().gui_get_focus_owner())
	if not buttons.is_empty():
		buttons[posmod(index + step, buttons.size())].grab_focus()


func _process(delta: float) -> void:
	if page == &"play":
		_update_tutorial()
		return
	if Arcade.guarded:
		return
	var direction := Vector2i.ZERO
	var input := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if input.length() > 0.3:
		if absf(input.x) > absf(input.y):
			direction.x = int(signf(input.x))
		else:
			direction.y = int(signf(input.y))
	_nav_timer -= delta
	if direction != Vector2i.ZERO and (direction != _nav_direction or _nav_timer <= 0.0):
		var focused := get_viewport().gui_get_focus_owner()
		var side := SIDE_RIGHT if direction.x > 0 else SIDE_LEFT
		if direction.y != 0:
			side = SIDE_BOTTOM if direction.y > 0 else SIDE_TOP
		if is_instance_valid(focused):
			var neighbor := focused.get_node_or_null(focused.get_focus_neighbor(side))
			if neighbor is Control:
				neighbor.grab_focus()
		_nav_timer = 0.32 if direction != _nav_direction else 0.17
	_nav_direction = direction
	if is_instance_valid(description):
		var scroll := description.get_v_scroll_bar()
		var amount := Input.get_action_strength("discard") - Input.get_action_strength("emergency heat")
		scroll.value += amount * 260.0 * delta
