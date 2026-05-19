extends Node2D

@onready var texture_rect = $DrawingArea/TextureRect
@onready var color_palette = $CanvasLayer/ColorPalette
@onready var next_button = $CanvasLayer/NextButton
@onready var eraser_button = $CanvasLayer/Erayser
@onready var save_button = $CanvasLayer/SaveButton

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

# Переменные для отслеживания раскраски
var total_white_pixels: int = 0
var colored_white_pixels: int = 0
var page_completed: bool = false
var min_pixels_required: int = 0  # 30% от белых пикселей

var brush_offsets: Array[Vector2i] = []
var brush_offsets_calculated: bool = false

var update_timer: float = 0.0
var needs_texture_update: bool = false
var update_delay: float = 0.016

func _ready():
	setup_palette_buttons_scale()
	load_pages()
	setup_color_buttons()
	
	texture_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	texture_rect.gui_input.connect(_on_texture_rect_gui_input)
	
	next_button.pressed.connect(_on_next_pressed)
	eraser_button.pressed.connect(_on_eraser_pressed)
	save_button.pressed.connect(_on_save_pressed)
	
	load_page(current_page)
	_calculate_brush_offsets()

func _on_texture_rect_gui_input(event: InputEvent):
	if page_completed:
		return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_drawing = true
			last_draw_pos = event.position
			draw_single_point_optimized(event.position)
			_update_texture_deferred()
		else:
			is_drawing = false
			_force_texture_update()
	
	elif event is InputEventMouseMotion and is_drawing:
		draw_line_between_optimized(last_draw_pos, event.position)
		last_draw_pos = event.position
		_update_texture_deferred()

func _on_save_pressed():
	if not texture_rect or not texture_rect.texture:
		return
	
	PopupHelper.show_confirmation(
		"Сохранить рисунок?",
		"Вы уверены, что хотите сохранить текущий рисунок?",
		_save_confirmed,
		func(): pass
	)

func _save_confirmed():
	var timestamp = Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
	var file_name = "coloring_page_%d_%s.png" % [current_page + 1, timestamp]
	
	var base_dir: String
	if OS.get_name() == "Android":
		base_dir = OS.get_system_dir(OS.SYSTEM_DIR_PICTURES)
		if base_dir.is_empty():
			base_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
	else:
		base_dir = OS.get_system_dir(OS.SYSTEM_DIR_PICTURES)
	
	var save_dir = base_dir.path_join("BrineTraining")
	if not DirAccess.dir_exists_absolute(save_dir):
		DirAccess.make_dir_absolute(save_dir)
	
	var file_path = save_dir.path_join(file_name)
	
	var saved_image = texture_rect.texture.get_image()
	var error = saved_image.save_png(file_path)
	
	if error == OK:
		var display_path = file_path
		if OS.get_name() == "Android":
			display_path = "Pictures/BrineTraining/" + file_name
		
		PopupHelper.show_notification(
			"Сохранено!",
			"Рисунок сохранён в папку\n" + display_path,
			true,
			3.0,
			Callable()
		)
	else:
		PopupHelper.show_notification(
			"Ошибка!",
			"Не удалось сохранить рисунок",
			false,
			2.0,
			Callable()
		)

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
	if not color_palette:
		return
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
	
	total_white_pixels = 0
	colored_white_pixels = 0
	page_completed = false
	
	for y in range(image_height):
		for x in range(image_width):
			var pixel = current_image.get_pixel(x, y)
			var brightness = (pixel.r + pixel.g + pixel.b) / 3.0
			if brightness < 0.5:
				current_image.set_pixel(x, y, Color.BLACK)
			else:
				current_image.set_pixel(x, y, Color.WHITE)
				total_white_pixels += 1
	
	# Рассчитываем 30% от белых пикселей
	min_pixels_required = int(total_white_pixels * 0.3)
	print("=== НОВАЯ СТРАНИЦА ===")
	print("Всего белых пикселей: ", total_white_pixels)
	print("Нужно закрасить минимум: ", min_pixels_required, " (30%)")
	
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.texture = ImageTexture.create_from_image(current_image)
	
	is_drawing = false
	needs_texture_update = false
	next_button.disabled = true

func setup_color_buttons():
	if not color_palette:
		return
	for button in color_palette.get_children():
		if button.has_signal("color_selected"):
			button.color_selected.connect(_on_color_selected)

func _on_color_selected(color: Color):
	current_color = color
	eraser = false
	print("Выбран цвет: ", current_color)

func _on_eraser_selected():
	current_color = eraser_color
	eraser = true
	print("Режим: ЛАСТИК")

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
			
			# ЛАСТИК: стирает ТОЛЬКО цветные пиксели
			if eraser:
				if pixel != Color.BLACK and pixel != Color.WHITE:
					current_image.set_pixel(ix, iy, Color.WHITE)
					if colored_white_pixels > 0:
						colored_white_pixels -= 1
					
					# Если закрашено меньше 30% - блокируем кнопку
					if colored_white_pixels < min_pixels_required and page_completed:
						page_completed = false
						next_button.disabled = true
						print("ЛАСТИК: закрашено ", colored_white_pixels, "/", min_pixels_required, " (нужно минимум)")
			
			# КИСТЬ: закрашивает ТОЛЬКО белые пиксели И цвет НЕ белый
			elif current_color != Color.WHITE:
				if pixel == Color.WHITE:
					current_image.set_pixel(ix, iy, current_color)
					colored_white_pixels += 1
					
					# Проверяем достижение 30%
					if colored_white_pixels >= min_pixels_required and not page_completed:
						page_completed = true
						next_button.disabled = false
						print("========== 30% ДОСТИГНУТО! КНОПКА АКТИВНА ==========")
						print("Закрашено: ", colored_white_pixels, " из ", min_pixels_required, " (30% от ", total_white_pixels, ")")
					elif colored_white_pixels % 1000 == 0:
						var progress_percent = int(float(colored_white_pixels) / total_white_pixels * 100)
						print("ЗАКРАШЕНО: ", colored_white_pixels, "/", total_white_pixels, " (", progress_percent, "%)")
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
	if not page_completed:
		var current_percent = int(float(colored_white_pixels) / total_white_pixels * 100)
		PopupHelper.show_notification(
			"Раскрась больше!",
			"Нужно раскрасить минимум 30% картинки.\nСейчас раскрашено: " + str(current_percent) + "%",
			false,
			2.0,
			Callable()
		)
		return
	
	if game_completed:
		return
	
	# Выдаём звезду за прохождение страницы
	GameManager.add_stars(1)
	
	current_page += 1
	
	if current_page >= coloring_pages.size():
		game_completed = true
		
		PopupHelper.show_notification(
			"ПОБЕДА!",
			"Ты раскрасил все картинки!",
			true,
			2.0,
			func(): 
				GameManager.open_game_selector()
		)
		return
	
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
