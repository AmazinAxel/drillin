extends CanvasLayer

@export var color_rect: ColorRect
@export var tween_speed: float = 0.6 

var _material: ShaderMaterial
var _displayed_intensity: float = 0.0
var _tween: Tween

func _ready() -> void:
	_material = color_rect.material as ShaderMaterial
	_material.set_shader_parameter("intensity", 0.0)
	color_rect.visible = false

func _process(_delta: float) -> void:
	var target: float = PoisonGlobals.intensity
	
	if abs(target - _displayed_intensity) > 0.01:
		_tween_to(target)
	
	color_rect.visible = true

func _tween_to(target: float) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_method(_set_shader_intensity, _displayed_intensity, target, tween_speed)

func _set_shader_intensity(value: float) -> void:
	_displayed_intensity = value
	_material.set_shader_parameter("intensity", value)
	
