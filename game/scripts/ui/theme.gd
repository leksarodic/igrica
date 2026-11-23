class_name UITheme
extends RefCounted
## A field notebook, not a dashboard. Bone paper, ink, copper hairlines, serif
## display type, and a single ember accent for the consequential.

const PAPER := Color("#e6dfce")
const PAPER_DIM := Color("#d6cfbd")
const INK := Color("#1d2325")
const INK_SOFT := Color("#4b4f4c")
const COPPER := Color("#a9764a")
const EMBER := Color("#c9613c")
const MINT := Color("#4c8578")

static var _serif: SystemFont
static var _sans: SystemFont
static var _serif_bold: SystemFont


static func safe_rect(viewport: Viewport) -> Rect2:
	if viewport == null:
		return Rect2(Vector2.ZERO, Vector2(1600, 900))
	var stretch := viewport.get_stretch_transform().get_scale()
	if stretch.x <= 0.001 or stretch.y <= 0.001:
		stretch = Vector2.ONE
	var base_size := viewport.get_visible_rect().size / stretch
	var win := DisplayServer.window_get_size()
	if win.x <= 0 or win.y <= 0:
		return Rect2(Vector2.ZERO, base_size)
	var safe := DisplayServer.get_display_safe_area()
	var px_to_base := base_size / Vector2(win)
	return Rect2(Vector2(safe.position) * px_to_base, Vector2(safe.size) * px_to_base)


static func ts(size: int) -> int:
	return maxi(10, int(round(size * Settings.text_scale)))


static func serif() -> SystemFont:
	if _serif == null:
		_serif = SystemFont.new()
		_serif.font_names = PackedStringArray(["Iowan Old Style", "Palatino", "Georgia", "Times New Roman"])
		_serif.font_weight = 500
	return _serif


static func serif_bold() -> SystemFont:
	if _serif_bold == null:
		_serif_bold = SystemFont.new()
		_serif_bold.font_names = serif().font_names
		_serif_bold.font_weight = 700
	return _serif_bold


static func sans() -> SystemFont:
	if _sans == null:
		_sans = SystemFont.new()
		_sans.font_names = PackedStringArray(["Avenir Next", "Helvetica Neue", "Arial"])
		_sans.font_weight = 400
	return _sans


static func paper_style(alpha: float = 0.97, padding: int = 22) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(PAPER.r, PAPER.g, PAPER.b, alpha)
	s.border_color = COPPER
	s.set_border_width_all(1)
	s.set_corner_radius_all(2)
	s.content_margin_left = padding
	s.content_margin_right = padding
	s.content_margin_top = padding
	s.content_margin_bottom = padding
	s.shadow_color = Color(0, 0, 0, 0.28)
	s.shadow_size = 12
	return s


static func dark_style(alpha: float = 0.88, padding: int = 22) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.07, 0.09, 0.10, alpha)
	s.border_color = COPPER
	s.set_border_width_all(1)
	s.set_corner_radius_all(2)
	s.content_margin_left = padding
	s.content_margin_right = padding
	s.content_margin_top = padding
	s.content_margin_bottom = padding
	return s


static func input_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.92, 0.89, 0.82, 0.9)
	s.border_color = Color(COPPER.r, COPPER.g, COPPER.b, 0.7)
	s.set_border_width_all(1)
	s.set_corner_radius_all(1)
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 7
	s.content_margin_bottom = 7
	return s


static func style_input(control: Control) -> void:
	if control == null:
		return
	control.add_theme_stylebox_override("normal", input_style())
	control.add_theme_stylebox_override("focus", input_style())
	control.add_theme_color_override("font_color", INK)
	control.add_theme_color_override("font_placeholder_color", INK_SOFT)
	control.add_theme_font_override("font", sans())
	control.add_theme_font_size_override("font_size", ts(17))
	if control is OptionButton:
		var popup := (control as OptionButton).get_popup()
		if popup != null:
			popup.add_theme_font_override("font", sans())
			popup.add_theme_font_size_override("font_size", ts(16))
			popup.add_theme_color_override("font_color", INK)


static func button(text: String, primary_color: Color = INK) -> Button:
	var b := Button.new()
	b.text = text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size = Vector2(0, 40)
	b.add_theme_font_override("font", sans())
	b.add_theme_font_size_override("font_size", ts(17))
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.10, 0.12, 0.13, 0.0)
	normal.border_color = Color(COPPER.r, COPPER.g, COPPER.b, 0.5)
	normal.set_border_width_all(1)
	normal.content_margin_left = 12
	normal.content_margin_right = 12
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8
	var hover := normal.duplicate()
	hover.bg_color = Color(COPPER.r, COPPER.g, COPPER.b, 0.16)
	hover.border_color = COPPER
	var pressed := normal.duplicate()
	pressed.bg_color = Color(COPPER.r, COPPER.g, COPPER.b, 0.28)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("focus", hover)
	b.add_theme_color_override("font_color", primary_color)
	b.add_theme_color_override("font_hover_color", EMBER if primary_color == INK else Color("#ffd9a0"))
	b.add_theme_color_override("font_pressed_color", primary_color)
	return b


static func heading(text: String, size: int = 28, color: Color = INK) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", serif_bold())
	l.add_theme_font_size_override("font_size", ts(size))
	l.add_theme_color_override("font_color", color)
	return l


static func body(text: String, size: int = 17, color: Color = INK) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_override("font", sans())
	l.add_theme_font_size_override("font_size", ts(size))
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("line_spacing", 4)
	return l


static func rule(width: float = 120.0, color: Color = COPPER) -> ColorRect:
	var r := ColorRect.new()
	r.color = color
	r.custom_minimum_size = Vector2(width, 1)
	r.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	return r


static func eyebrow(text: String) -> Label:
	var l := Label.new()
	l.text = text.to_upper()
	l.add_theme_font_override("font", sans())
	l.add_theme_font_size_override("font_size", ts(12))
	l.add_theme_color_override("font_color", COPPER)
	return l
