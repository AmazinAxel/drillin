extends Node2D

@export var backgroundScrollSpeed: float = 200.0
var background2: Node2D
var bg_height: float

func _ready() -> void:
	setupBackground()
	
func setupBackground():
	var tilemap = $Background.get_node("TileMapLayer")
	var used_rect = tilemap.get_used_rect()
	bg_height = used_rect.size.y * tilemap.tile_set.tile_size.y
	
	background2 = $Background.duplicate()
	$Background.get_parent().add_child(background2)
	background2.position = $Background.position + Vector2(0, bg_height)
	
func _process(delta: float) -> void:
	$Background.position.y -= backgroundScrollSpeed * delta
	background2.position.y -= backgroundScrollSpeed * delta

	if $Background.position.y + bg_height < 0:
		$Background.position.y = background2.position.y + bg_height
	if background2.position.y + bg_height < 0:
		background2.position.y = $Background.position.y + bg_height
