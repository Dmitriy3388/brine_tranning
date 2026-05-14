extends Node2D

@onready var drawing_area = $DrawingArea
@onready var texture_rect = $DrawingArea/TextureRect
@onready var color_palette = $CanvasLayer/ColorPalette
@onready var next_button = $CanvasLayer/NextButton
@onready var eraser_button = $CanvasLayer/Erayser

var eraser = false
var current_image: Image
var current_color: Color = Color.WHITE
var eraser_color: Color = Color.WHITE
var current_page: int = 0
var coloring_pages: Array[Texture2D] = []
var brush_size: int = 15
var max_height: int = 700
var last_draw_pos: Vector2 = Vector2.ZERO
var is_drawing: bool = false
var game_completed: bool = false

var brush_offsets: Array[Vector2i] = []
var brush_offsets_calculated: bool = false

var update_timer: float = 0.0
var needs_texture_update: bool = false
var update_delay: float = 0.016

func _ready():
	setup_palette_buttons_scale()
	load_pages()
	load_page(current_page)
	setup_color_buttons()
	
	drawing_area.draw_start.connect(_on_draw_start)
	drawing_area.draw_move.connect(_on_draw_move)
	drawing_area.draw_end.connect(_on_draw_end)
	next_button.pressed.connect(_on_next_pressed)
	eraser_button.pressed.connect(_on_eraser_pressed)
	
	_calculate_brush_offsets()

func _calculate_brush_offsets():
	if brush_offsets_calculated:
		return
	
	for dx in range(-brush_size, brush_size + 1):
		for dy in range(-brush_size, brush_size + 1):
			var distance = sqrt(dx*dx + dy*dy)
			if distance <= brush_size:
				brush_offsets.append(Vector2i(dx, dy))
	
	brush_offsets_calculated = true

func setup_palette_buttons_scale():
	for button in color_palette.get_children():
		if button is TouchScreenButton:
			button.scale = Vector2(0.8, 0.8)

func load_pages():
	coloring_pages.append(preload("res://assets/game_5/pages/page1.png"))
	coloring_pages.append(preload("res://assets/game_5/pages/page2.png"))

func load_page(index: int):
	var texture = coloring_pages[index]
	current_image = texture.get_image()
	current_image = resize_image_to_height(current_image, max_height)
	
	var image_width = current_image.get_width()
	var image_height = current_image.get_height()
	
	for y in range(image_height):
		for x in range(image_width):
			var pixel = current_image.get_pixel(x, y)
			var brightness = (pixel.r + pixel.g + pixel.b) / 3.0
			if brightness < 0.5:
				current_image.set_pixel(x, y, Color.BLACK)
			else:
				current_image.set_pixel(x, y, Color.WHITE)
	
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.texture = ImageTexture.create_from_image(current_image)
	
	is_drawing = false
	needs_texture_update = false

func setup_color_buttons():
	for button in color_palette.get_children():
		if button.has_signal("color_selected"):
			button.color_selected.connect(_on_color_selected)

func _on_color_selected(color: Color):
	current_color = color
	eraser = false

func _on_eraser_selected():
	current_color = eraser_color
	eraser = true

func _on_draw_start(pos: Vector2):
	is_drawing = true
	last_draw_pos = pos
	draw_single_point_optimized(pos)
	_update_texture_deferred()

func _on_draw_move(pos: Vector2):
	if not is_drawing:
		return
	draw_line_between_optimized(last_draw_pos, pos)
	last_draw_pos = pos
	_update_texture_deferred()

func _on_draw_end():
	is_drawing = false
	_force_texture_update()

func draw_line_between_optimized(from_pos: Vector2, to_pos: Vector2):
	var distance = from_pos.distance_to(to_pos)
	if distance < 1:
		draw_single_point_optimized(to_pos)
		return
	
	var steps = max(1, int(distance / max(3, brush_size / 3)))
	for i in range(steps + 1):
		var t = float(i) / steps
		var interpolated_pos = from_pos.lerp(to_pos, t)
		draw_single_point_optimized(interpolated_pos)

func draw_single_point_optimized(pos: Vector2):
	var image_width = current_image.get_width()
	var image_height = current_image.get_height()
	var texture_rect_size = texture_rect.size
	
	var scale_x = texture_rect_size.x / float(image_width)
	var scale_y = texture_rect_size.y / float(image_height)
	var scale = min(scale_x, scale_y)
	
	var displayed_width = image_width * scale
	var displayed_height = image_height * scale
	var offset_x = (texture_rect_size.x - displayed_width) / 2
	var offset_y = (texture_rect_size.y - displayed_height) / 2
	
	var image_x = (pos.x - offset_x) / scale
	var image_y = (pos.y - offset_y) / scale
	var center_ix = int(image_x)
	var center_iy = int(image_y)
	
	for offset in brush_offsets:
		var ix = center_ix + offset.x
		var iy = center_iy + offset.y
		if ix >= 0 and ix < image_width and iy >= 0 and iy < image_height:
			var pixel = current_image.get_pixel(ix, iy)
			if eraser:
				if pixel != Color.BLACK:
					current_image.set_pixel(ix, iy, eraser_color)
			else:
				if pixel == Color.WHITE:
					current_image.set_pixel(ix, iy, current_color)

func _update_texture_deferred():
	needs_texture_update = true

func _force_texture_update():
	if needs_texture_update:
		texture_rect.texture = ImageTexture.create_from_image(current_image)
		needs_texture_update = false

func _process(delta):
	if needs_texture_update:
		update_timer += delta
		if update_timer >= update_delay:
			update_timer = 0.0
			_force_texture_update()

func _on_next_pressed():
	if game_completed:
		return
	
	current_page += 1
	
	if current_page >= coloring_pages.size():
		game_completed = true
		GameManager.complete_game("game_5")
		
		PopupHelper.show_notification(
			"ПОБЕДА!",
			"Ты раскрасил все картинки!\n+" + str(GameManager.STARS_REWARD) + " звезды!",
			true,
			2.0,
			func(): 
				GameManager.open_game_selector()
		)
		return
	
	current_color = Color.WHITE
	load_page(current_page)
	is_drawing = false
	_force_texture_update()

func _on_eraser_pressed():
	_on_eraser_selected()

func resize_image_to_height(image: Image, target_height: int) -> Image:
	var height = image.get_height()
	if height <= target_height:
		return image
	
	var scale = float(target_height) / float(height)
	var new_width = max(1, int(image.get_width() * scale))
	image.resize(new_width, target_height, Image.INTERPOLATE_LANCZOS)
	return image
