extends Node

var intensity_per_hit: float = 0.4
var max_intensity: float = 3.0
var fade_speed: float = 0.05
var fade_threshold: float = 0.05

var intensity: float = 0.0

func _process(delta: float) -> void:
	if intensity > 0.0:
		intensity = max(0.0, intensity - fade_speed * delta)
		if intensity < fade_threshold:
			intensity = 0.0

func add_poison(amount: float = -1.0) -> void:
	var hit_amount := intensity_per_hit if amount < 0.0 else amount
	intensity = min(intensity + hit_amount, max_intensity)

func clear_poison() -> void:
	intensity = 0.0
