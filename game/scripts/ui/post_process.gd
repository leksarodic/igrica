class_name PostProcess
extends CanvasLayer
## One full-screen grade. It is intentionally subtle and can be disabled by the
## reduced-motion / low-quality settings.

var _rect: ColorRect
var _material: ShaderMaterial


func _ready() -> void:
	layer = 4
	_rect = ColorRect.new()
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := load("res://assets/shaders/grade.gdshader") as Shader
	if shader != null:
		_material = ShaderMaterial.new()
		_material.shader = shader
		_rect.material = _material
	add_child(_rect)
	_apply()
	Events.settings_changed.connect(func(_k, _v): _apply())


func _apply() -> void:
	if _material == null:
		return
	_material.set_shader_parameter("saturation", 1.0 if Settings.high_contrast else 1.08)
	_material.set_shader_parameter("contrast", 1.18 if Settings.high_contrast else 1.06)
	_material.set_shader_parameter("vignette", 0.0 if Settings.reduced_motion else 0.28)
	_rect.visible = Settings.quality != "low"
