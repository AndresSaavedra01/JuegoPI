extends TextureRect
class_name Heart

@onready var sprite : Sprite2D = $sprite

func fullHeart():
	sprite.region_rect.position.x = 0
	
func mediumHeart():
	sprite.region_rect.position.x = 550
	
func emptyHeart():
	sprite.region_rect.position.x = 1080

func isFull() -> bool:
	return sprite.region_rect.position.x == 0
	
func isMedium() -> bool:
	return sprite.region_rect.position.x == 550
	
func isEmpty() -> bool:
	return sprite.region_rect.position.x == 1080
