extends Control

signal draw_start(pos)
signal draw_move(pos)
signal draw_end()

var is_drawing: bool = false
var last_update_time: float = 0.0
var min_update_interval: float = 0.01  # Минимум 10ms между обновлениями (~100 FPS)

func _ready():
	gui_input.connect(_on_gui_input)

func _on_gui_input(event: InputEvent):
	if event is InputEventScreenTouch:
		if event.pressed:
			is_drawing = true
			var local_pos = get_local_mouse_position()
			if _is_valid_position(local_pos):
				draw_start.emit(local_pos)
				last_update_time = Time.get_ticks_msec() / 1000.0
		else:
			if is_drawing:
				is_drawing = false
				draw_end.emit()
	
	if event is InputEventScreenDrag and is_drawing:
		var current_time = Time.get_ticks_msec() / 1000.0
		# Ограничиваем частоту отправки событий
		if current_time - last_update_time >= min_update_interval:
			var local_pos = get_local_mouse_position()
			if _is_valid_position(local_pos):
				draw_move.emit(local_pos)
				last_update_time = current_time

func _is_valid_position(pos: Vector2) -> bool:
	if pos.x < 0 or pos.y < 0:
		return false
	if pos.x > size.x or pos.y > size.y:
		return false
	return true
