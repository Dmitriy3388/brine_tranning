extends Node

## Глобальный синглтон для управления визуальными эффектами во всей игре.
## Автоматически находит кнопки, задает им объемный глянцевый 3D-стиль с бликами
## и добавляет к ним эффект круглых пузырьков при нажатии.

var _bubble_texture: Texture2D

# Процедурные стили для объемных 3D кнопок
var _style_normal: StyleBoxTexture
var _style_hover: StyleBoxTexture
var _style_pressed: StyleBoxTexture

# Кэш стилей для разных цветов
var _color_styles: Dictionary = {}

func _ready():
	# Чтобы эффекты работали постоянно, синглтон не должен вставать на паузу вместе с игрой
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Создаем красивую круглую текстуру пузыря с бликом при старте игры
	_generate_bubble_texture()
	
	# Генерируем премиальные текстуры и StyleBox для объемных кнопок
	_generate_glossy_button_styles()
	
	# Подключаемся к системному сигналу добавления любого узла в дерево сцены
	get_tree().node_added.connect(_on_node_added)
	
	# Обрабатываем все узлы, которые уже успели загрузиться на момент старта игры
	_connect_existing_buttons(get_tree().root)

## Процедурная генерация круглой текстуры мыльного пузыря с бликом
func _generate_bubble_texture():
	var size = 64
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = Vector2(size / 2.0, size / 2.0)
	var max_radius = size / 2.0 - 1.5
	
	for y in range(size):
		for x in range(size):
			var pos = Vector2(x + 0.5, y + 0.5)
			var dist = pos.distance_to(center)
			
			if dist <= max_radius:
				var edge_dist = max_radius - dist
				var alpha = 0.0
				
				# Тонкая светящаяся кайма пузыря
				if edge_dist < 3.0:
					alpha = lerp(1.0, 0.15, edge_dist / 3.0)
				else:
					# Полупрозрачная внутренняя часть
					alpha = lerp(0.15, 0.0, (edge_dist - 3.0) / (max_radius - 3.0))
				
				# Симпатичный круглый блик в левом верхнем углу пузырька
				var highlight_pos = center - Vector2(size / 5.2, size / 5.2)
				var dist_to_highlight = pos.distance_to(highlight_pos)
				var highlight_radius = size / 5.0
				if dist_to_highlight < highlight_radius:
					var highlight_alpha = lerp(0.85, 0.0, dist_to_highlight / highlight_radius)
					alpha = max(alpha, highlight_alpha)
				
				image.set_pixel(x, y, Color(1, 1, 1, alpha))
				
	_bubble_texture = ImageTexture.create_from_image(image)

## Определение цвета кнопки по ее тексту
func _get_button_color(button_text: String) -> Color:
	var text_lower = button_text.to_lower().strip_edges()
	
	# ИГРАТЬ - желтый
	if "играть" in text_lower:
		return Color(0.95, 0.75, 0.25, 1.0)  # Золотисто-желтый
	
	# НАСТРОЙКИ - голубой
	if "настройк" in text_lower:
		return Color(0.3, 0.7, 0.9, 1.0)  # Голубой
	
	# ПРОДОЛЖИТЬ - красный
	if "продолж" in text_lower:
		return Color(0.85, 0.25, 0.25, 1.0)  # Красный
	
	# ВЫХОД - зеленый
	if "выход" in text_lower:
		return Color(0.25, 0.75, 0.35, 1.0)  # Зеленый
	
	# Кнопки выбора игры - оранжевые
	if "выбери" in text_lower or "профессии" in text_lower or "лабиринт" in text_lower or "пазлы" in text_lower or "раскраска" in text_lower:
		return Color(0.95, 0.55, 0.2, 1.0)  # Оранжевый
	
	# Стандартный фиолетовый для всех остальных кнопок
	return Color(0.48, 0.28, 0.72, 1.0)

## Получение или создание стиля для определенного цвета
func _get_style_for_color(base_color: Color, is_pressed: bool, is_hover: bool) -> StyleBoxTexture:
	var cache_key = "%s_%s_%s" % [base_color.to_html(), is_pressed, is_hover]
	
	if _color_styles.has(cache_key):
		return _color_styles[cache_key]
	
	var tex = _create_glossy_texture(base_color, is_pressed, is_hover)
	var style = _create_stylebox_from_texture(tex)
	_color_styles[cache_key] = style
	return style

## Процедурная генерация текстур для стеклянных/глянцевых кнопок (9-патч)
func _generate_glossy_button_styles():
	# Генерируем базовый фиолетовый стиль (для кнопок без особого цвета)
	var base_purple = Color(0.48, 0.28, 0.72)
	
	var tex_normal = _create_glossy_texture(base_purple, false, false)
	var tex_hover = _create_glossy_texture(base_purple.lightened(0.15), false, true)
	var tex_pressed = _create_glossy_texture(base_purple.darkened(0.25), true, false)
	
	_style_normal = _create_stylebox_from_texture(tex_normal)
	_style_hover = _create_stylebox_from_texture(tex_hover)
	_style_pressed = _create_stylebox_from_texture(tex_pressed)

## Вспомогательный метод для генерации самой текстуры объемной кнопки во всех деталях
func _create_glossy_texture(base_color: Color, is_pressed: bool, is_hover: bool) -> Texture2D:
	var size_x = 128
	var size_y = 128
	var image = Image.create(size_x, size_y, false, Image.FORMAT_RGBA8)
	
	var corner_radius = 24.0
	
	# Параметры градиента в зависимости от состояния
	var color_top: Color
	var color_bottom: Color
	
	if is_pressed:
		# НАЖАТОЕ СОСТОЯНИЕ: кнопка темная, приплюснутая
		color_top = base_color.darkened(0.35)
		color_bottom = base_color.darkened(0.2)
	elif is_hover:
		# НАВЕДЕНИЕ: ярче обычного, усиленный блик
		color_top = base_color.lightened(0.3)
		color_bottom = base_color.lightened(0.05)
	else:
		# ОБЫЧНОЕ СОСТОЯНИЕ: нормальный градиент
		color_top = base_color.lightened(0.2)
		color_bottom = base_color.darkened(0.25)
	
	for y in range(size_y):
		for x in range(size_x):
			# 1. Алгоритм скругления углов (SDF rounded box)
			var dx = max(0, abs(x - size_x / 2.0) - (size_x / 2.0 - corner_radius))
			var dy = max(0, abs(y - size_y / 2.0) - (size_y / 2.0 - corner_radius))
			var dist_to_corner = sqrt(dx*dx + dy*dy)
			
			if dist_to_corner > corner_radius:
				image.set_pixel(x, y, Color.TRANSPARENT)
				continue
				
			# Сглаживание краев (Antialiasing)
			var edge_alpha = 1.0
			if dist_to_corner > corner_radius - 1.0:
				edge_alpha = corner_radius - dist_to_corner
			
			# 2. Базовый вертикальный градиент
			var t_gradient = float(y) / float(size_y)
			var pixel_color = color_top.lerp(color_bottom, t_gradient)
			
			# 3. Эффект 3D Bevel (только для обычного и hover состояний)
			if not is_pressed:
				# Верхний свет (только для обычного и hover)
				if y <= 4:
					var bevel_t = 1.0 - (y / 4.0)
					pixel_color = pixel_color.lerp(Color.WHITE, bevel_t * 0.45)
				# Нижняя тень
				elif y >= size_y - 6:
					var shadow_t = (y - (size_y - 6)) / 6.0
					pixel_color = pixel_color.lerp(Color.BLACK, shadow_t * 0.5)
			else:
				# НАЖАТОЕ СОСТОЯНИЕ: эффект вдавленности (тень сверху)
				if y <= 5:
					var bevel_t = 1.0 - (y / 5.0)
					pixel_color = pixel_color.lerp(Color.BLACK, bevel_t * 0.4)
			
			# 4. Объемный эллиптический глянцевый блик (Gloss Sheen) - только для обычного и hover
			if not is_pressed:
				# Дугообразный блик в верхней половине кнопки
				var center_highlight = Vector2(size_x / 2.0, -10)
				var radius_highlight_x = size_x * 0.8
				var radius_highlight_y = size_y * 0.55
				
				var ellipse_val = (pow(x - center_highlight.x, 2) / pow(radius_highlight_x, 2)) + (pow(y - center_highlight.y, 2) / pow(radius_highlight_y, 2))
				
				if ellipse_val < 1.0 and y < size_y * 0.45:
					# Создаем мягкое отражение света с затуханием к центру
					var gloss_intensity = (1.0 - ellipse_val) * (1.0 - (float(y) / (size_y * 0.45)))
					var max_sheen = 0.35 if is_hover else 0.22
					pixel_color = pixel_color.lerp(Color.WHITE, gloss_intensity * max_sheen)
			
			# Применяем прозрачность антиалиасинга
			pixel_color.a = edge_alpha
			image.set_pixel(x, y, pixel_color)
			
	return ImageTexture.create_from_image(image)

## Настройка масштабируемого 9-патча StyleBoxTexture
func _create_stylebox_from_texture(tex: Texture2D) -> StyleBoxTexture:
	var style = StyleBoxTexture.new()
	style.texture = tex
	
	# Границы 9-патча (чтобы углы не растягивались)
	style.texture_margin_left = 16
	style.texture_margin_right = 16
	style.texture_margin_top = 16
	style.texture_margin_bottom = 16
	
	# Внутренние отступы контента (текста внутри кнопки)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 18
	style.content_margin_bottom = 22
	
	return style

## Рекурсивно сканирует дерево на наличие кнопок на старте
func _connect_existing_buttons(node: Node):
	_try_connect_node(node)
	for child in node.get_children():
		_connect_existing_buttons(child)

## Отслеживает появление новых узлов в процессе игры
func _on_node_added(node: Node):
	_try_connect_node.call_deferred(node)

## Вспомогательная функция для определения кнопок управления персонажем
func _is_movement_control(node: Node) -> bool:
	if not is_instance_valid(node):
		return false
		
	var name_lower = node.name.to_lower()
	
	# Исключаем ложные срабатывания на кнопки главного верхнего бара и обычного меню
	if "top" in name_lower or "bar" in name_lower or "menu" in name_lower or "settings" in name_lower:
		return false
		
	# Проверяем, содержит ли имя самой кнопки указания на направления движения
	if "up" in name_lower or "down" in name_lower or "left" in name_lower or "right" in name_lower or "arrow" in name_lower:
		return true
		
	# Проверяем имя родительского контейнера
	var parent = node.get_parent()
	if parent:
		var parent_name_lower = parent.name.to_lower()
		
		# Игнорируем стандартные панели TopBar и UI меню
		if "topbar" in parent_name_lower or "panel" in parent_name_lower or "hbox" in parent_name_lower or "vbox" in parent_name_lower:
			return false
			
		# Точечно фильтруем только контейнеры виртуального джойстика или клавиш движения
		if "joystick" in parent_name_lower or "movement" in parent_name_lower or "touch_control" in parent_name_lower or "direction" in parent_name_lower or "pad" in parent_name_lower:
			return true
			
	return false

## Попытка подключить эффект к узлу, если он является кнопкой
func _try_connect_node(node: Node):
	if not is_instance_valid(node):
		return
		
	# Игнорируем кнопки, отвечающие за управление перемещением
	if _is_movement_control(node):
		return
		
	if node is BaseButton:
		if node is Button:
			_apply_glossy_theme(node)
			
		if not node.pressed.is_connected(_on_button_pressed.bind(node)):
			node.pressed.connect(_on_button_pressed.bind(node))
	elif node is TouchScreenButton:
		if not node.pressed.is_connected(_on_touch_button_pressed.bind(node)):
			node.pressed.connect(_on_touch_button_pressed.bind(node))

## Принудительное наложение сгенерированной объемной 3D-темы на кнопку
func _apply_glossy_theme(button: Button):
	if not is_instance_valid(button):
		return
	
	# Получаем текст кнопки
	var button_text = button.text
	
	# Определяем цвет для этой кнопки
	var base_color = _get_button_color(button_text)
	
	# Если цвет не стандартный фиолетовый, генерируем кастомные стили
	if base_color != Color(0.48, 0.28, 0.72, 1.0):
		var style_normal = _get_style_for_color(base_color, false, false)
		var style_hover = _get_style_for_color(base_color, false, true)
		var style_pressed = _get_style_for_color(base_color, true, false)
		
		button.add_theme_stylebox_override("normal", style_normal)
		button.add_theme_stylebox_override("hover", style_hover)
		button.add_theme_stylebox_override("pressed", style_pressed)
		button.add_theme_stylebox_override("focus", style_normal)
	else:
		# Используем стандартные фиолетовые стили
		if _style_normal:
			button.add_theme_stylebox_override("normal", _style_normal)
		if _style_hover:
			button.add_theme_stylebox_override("hover", _style_hover)
		if _style_pressed:
			button.add_theme_stylebox_override("pressed", _style_pressed)
		if _style_normal:
			button.add_theme_stylebox_override("focus", _style_normal)
	
	# Цвет шрифта
	button.add_theme_color_override("font_color", Color(0.98, 0.98, 1.0))
	button.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 0.85))
	button.add_theme_color_override("font_pressed_color", Color(0.85, 0.75, 0.95))

## Обработчик нажатия для стандартных кнопок интерфейса
func _on_button_pressed(button: BaseButton):
	if not is_instance_valid(button) or not button.is_visible_in_tree():
		return
		
	# Игнорируем нажатие, если оно было вызвано клавишей Пробел
	if Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_SPACE):
		return
	
	var spawn_pos = button.get_global_mouse_position()
	_spawn_sparks(spawn_pos)

## Обработчик нажатия для сенсорных кнопок
func _on_touch_button_pressed(touch_button: TouchScreenButton):
	if not is_instance_valid(touch_button) or not touch_button.is_visible_in_tree():
		return
		
	if Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_SPACE):
		return
		
	var spawn_pos = touch_button.get_global_mouse_position()
	_spawn_sparks(spawn_pos)

## Функция спавна частиц пузырьков
func _spawn_sparks(spawn_pos: Vector2):
	var particles = CPUParticles2D.new()
	
	if _bubble_texture:
		particles.texture = _bubble_texture
	
	var current_scene = get_tree().current_scene
	if is_instance_valid(current_scene):
		current_scene.add_child(particles)
	else:
		get_tree().root.add_child(particles)
		
	particles.global_position = spawn_pos
	
	# --- НАСТРОЙКИ ДЛЯ КРУПНЫХ И ОТЧЕТЛИВЫХ ПУЗЫРЕЙ ---
	particles.amount = 20                     # Больше пузырей
	particles.lifetime = 1.2                  # Дольше живут
	particles.one_shot = true
	particles.explosiveness = 0.85
	particles.spread = 120.0
	particles.direction = Vector2.UP
	particles.gravity = Vector2(0, -200)
	particles.initial_velocity_min = 120.0    # Быстрее вылетают
	particles.initial_velocity_max = 220.0
	particles.damping_min = 45.0
	particles.damping_max = 70.0
	
	# Размер пузырей (крупные и заметные)
	particles.scale_amount_min = 0.35
	particles.scale_amount_max = 0.85
	
	# График изменения масштаба
	var scale_curve = Curve.new()
	scale_curve.add_point(Vector2(0.0, 0.3))
	scale_curve.add_point(Vector2(0.2, 1.0))
	scale_curve.add_point(Vector2(0.85, 0.9))
	scale_curve.add_point(Vector2(1.0, 0.0))
	particles.scale_amount_curve = scale_curve
	
	# Цветовая гамма (более яркая, прозрачность чуть выше среднего)
	var gradient = Gradient.new()
	gradient.set_color(0, Color(0.75, 0.95, 1.0, 0.92))   # Яркий, почти непрозрачный
	gradient.set_color(1, Color(0.98, 0.8, 1.0, 0.4))
	gradient.add_point(0.5, Color(0.6, 1.0, 0.9, 0.7))
	particles.color_ramp = gradient
	
	particles.emitting = true
	
	var timer = get_tree().create_timer(particles.lifetime + 0.1)
	timer.timeout.connect(particles.queue_free)
