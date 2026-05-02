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

func _ready():
	setup_palette_buttons_scale()
	load_pages()
	load_page(current_page)
	setup_color_buttons()
	drawing_area.draw_point.connect(_on_draw_point)
	next_button.pressed.connect(_on_next_pressed)
	eraser_button.pressed.connect(_on_eraser_pressed)

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
	
	for x in range(current_image.get_width()):
		for y in range(current_image.get_height()):
			var pixel = current_image.get_pixel(x, y)
			var brightness = (pixel.r + pixel.g + pixel.b) / 3.0
			if brightness < 0.5:
				current_image.set_pixel(x, y, Color.BLACK)
			else:
				current_image.set_pixel(x, y, Color.WHITE)
	
	texture_rect.texture = ImageTexture.create_from_image(current_image)
	
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

func _on_draw_point(pos: Vector2):
	var local_pos = pos
	var image_width = current_image.get_width()
	var image_height = current_image.get_height()
	
	var texture_rect_size = texture_rect.size
	var offset_x = (texture_rect_size.x - image_width) / 2
	var offset_y = (texture_rect_size.y - image_height) / 2
	
	for dx in range(-brush_size, brush_size + 1):
		for dy in range(-brush_size, brush_size + 1):
			var distance = sqrt(dx*dx + dy*dy)
			if distance > brush_size:
				continue
			
			var image_x = (local_pos.x - offset_x + dx) / texture_rect_size.x * image_width
			var image_y = (local_pos.y - offset_y + dy) / texture_rect_size.y * image_height
			
			var ix = int(image_x)
			var iy = int(image_y)
			
			if ix >= 0 and ix < image_width and iy >= 0 and iy < image_height:
				var pixel = current_image.get_pixel(ix, iy)
				
				if eraser:
					# Eraser: erase only if pixel is NOT black contour
					if pixel != Color.BLACK:
						current_image.set_pixel(ix, iy, eraser_color)
				else:
					# Brush: color only white pixels
					if pixel == Color.WHITE:
						current_image.set_pixel(ix, iy, current_color)
	
	texture_rect.texture = ImageTexture.create_from_image(current_image)

func _on_next_pressed():
	current_page += 1
	if current_page >= coloring_pages.size():
		current_page = 0
	load_page(current_page)

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
