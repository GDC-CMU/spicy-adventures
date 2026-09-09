extends RefCounted
## One small, static theme; no replacement textures or new flashing animation.

const INK = Color("#112a40")
const PANEL = Color("#10283a")
const ICE = Color("#c4f4ff")
const GOLD = Color("#ffd269")
const TEXT = Color("#f2faff")
const MUTED = Color("#bad3e0")


static func panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL
	style.border_color = Color("#456b82")
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style


static func create_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 28
	theme.set_color("font_color", "Button", TEXT)
	theme.set_color("font_focus_color", "Button", TEXT)
	theme.set_color("font_hover_color", "Button", TEXT)
	theme.set_color("font_color", "Label", TEXT)
	theme.set_color("default_color", "RichTextLabel", TEXT)
	theme.set_font_size("normal_font_size", "RichTextLabel", 28)
	var normal := panel_style()
	normal.bg_color = INK
	theme.set_stylebox("normal", "Button", normal)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("#234d65")
	hover.border_color = ICE
	theme.set_stylebox("hover", "Button", hover)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("#31627b")
	theme.set_stylebox("pressed", "Button", pressed)
	var focus := StyleBoxFlat.new()
	focus.draw_center = false
	focus.border_color = GOLD
	focus.set_border_width_all(4)
	focus.set_corner_radius_all(8)
	theme.set_stylebox("focus", "Button", focus)
	theme.set_stylebox("panel", "Panel", panel_style())
	theme.set_stylebox("panel", "PanelContainer", panel_style())
	return theme
