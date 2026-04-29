extends Panel

var is_filled = false
var correct_id = 0

func _ready():
	add_to_group("slots")
	modulate = Color(0.8, 0.8, 0.8, 1)

func place_piece(piece):
	if is_filled:
		return false
	
	is_filled = true
	modulate = Color(1, 1, 1, 1)
	
	var texture_rect = TextureRect.new()
	texture_rect.texture = piece.texture_normal
	texture_rect.size = size
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(texture_rect)
	
	return true
