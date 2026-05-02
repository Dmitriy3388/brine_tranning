extends Control

signal draw_point(pos)

@onready var texture_rect = $TextureRect

var is_drawing: bool = false

func _ready():
	gui_input.connect(_on_gui_input)

func _on_gui_input(event: InputEvent):
	if event is InputEventScreenTouch:
		if event.pressed:
			is_drawing = true
			draw_at(event.position)
		else:
			is_drawing = false
	
	if event is InputEventScreenDrag and is_drawing:
		draw_at(event.position)

func draw_at(_pos: Vector2):  # ← добавили _ перед pos
	var local_pos = get_local_mouse_position()
	if local_pos.x < 0 or local_pos.y < 0:
		return
	
	draw_point.emit(local_pos)
