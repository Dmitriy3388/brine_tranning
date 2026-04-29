extends TextureButton

var target_position = Vector2.ZERO
var start_position = Vector2.ZERO
var is_placed = false
var drag_offset = Vector2.ZERO
var is_dragging = false

func _ready():
	start_position = global_position

func _input(event):
	if is_placed:
		return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var rect = Rect2(global_position, size)
			if rect.has_point(event.global_position):
				is_dragging = true
				drag_offset = global_position - event.global_position
		else:
			if is_dragging:
				is_dragging = false
				check_snap()

func _process(_delta):
	if is_dragging and not is_placed:
		global_position = get_global_mouse_position() + drag_offset

func check_snap():
	if global_position.distance_to(target_position) < 70:
		global_position = target_position
		is_placed = true
		get_node("/root/Game4").on_piece_placed()
	else:
		global_position = start_position
