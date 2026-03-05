extends Node

var level = 0;
var health = 100;
var damageReduction = 1;
var shootSpeed = 1;
var attackDamage = 2;
var minerals = 0;
var riskChance = 10;

var isAttacking: bool = false;

var baseRotation = 0;

var isDead := false;


func screen_shake(strength: float, duration: float):
	var camera = get_viewport().get_camera_2d()
	if not camera:
		return # could prevent errors idk

	var tween = create_tween()
	tween.tween_method(func(t):
		camera.offset = Vector2(randf_range(-strength, strength), randf_range(-strength, strength))
	, 0.0, 1.0, duration)
	tween.tween_callback(func(): camera.offset = Vector2.ZERO)
