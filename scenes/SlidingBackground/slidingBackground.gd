extends Node2D

@export var backgroundScrollSpeed: float = 200.0
@export var shakeStrength: float = 0.8

var background2: Node2D
var bg_height: float
var shake_origin: Vector2

func _ready() -> void:
	shake_origin = position
	setupBackground()
	
func setupBackground():
	var tilemap = $Background.get_node("TileMapLayer")
	var used_rect = tilemap.get_used_rect()
	bg_height = used_rect.size.y * tilemap.tile_set.tile_size.y
	
	background2 = $Background.duplicate()
	$Background.get_parent().add_child(background2)
	background2.position = $Background.position + Vector2(0, bg_height)
	
func _process(delta: float) -> void:
	position = shake_origin + Vector2(
		randf_range(-shakeStrength, shakeStrength),
		randf_range(-shakeStrength, shakeStrength)
	)
	
	$Background.position.y -= backgroundScrollSpeed * delta
	background2.position.y -= backgroundScrollSpeed * delta

	if $Background.position.y + bg_height < 0:
		$Background.position.y = background2.position.y + bg_height
	if background2.position.y + bg_height < 0:
		background2.position.y = $Background.position.y + bg_height
