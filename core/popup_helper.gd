extends CanvasLayer

var popup_style: StyleBoxFlat
var active_popup: PopupPanel = null

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_style()
	hide()

func _load_style():
	# Загружаем созданный тобой стиль из папки ui
	if ResourceLoader.exists("res://core/resourses/popup_style.tres"):
		popup_style = load("res://core/resourses/popup_style.tres")
		print("Popup style loaded successfully")
	else:
		# Если файла нет — создаём стиль по умолчанию (как запасной вариант)
		print("Warning: popup_style.tres not found, creating default style")
		_create_default_style()

func _create_default_style():
	popup_style = StyleBoxFlat.new()
	popup_style.bg_color = Color(0.15, 0.15, 0.2, 0.95)
	popup_style.border_width_left = 2
	popup_style.border_width_right = 2
	popup_style.border_width_top = 2
	popup_style.border_width_bottom = 2
	popup_style.border_color = Color(0.3, 0.7, 0.3, 1)
	popup_style.corner_radius_top_left = 10
	popup_style.corner_radius_top_right = 10
	popup_style.corner_radius_bottom_left = 10
	popup_style.corner_radius_bottom_right = 10

func show_notification(title: String, message: String, is_success: bool = true, duration: float = 2.0, on_closed: Callable = Callable()):
	# Удаляем старый попап, если есть
	if active_popup:
		active_popup.queue_free()
		active_popup = null
	
	var popup = PopupPanel.new()
	popup.title = title
	popup.size = Vector2i(350, 150)
	popup.exclusive = true
	popup.popup_window = false
	
	# ПРИМЕНЯЕМ ЗАГРУЖЕННЫЙ СТИЛЬ
	if popup_style:
		popup.add_theme_stylebox_override("panel", popup_style)
	
	var vbox = VBoxContainer.new()
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	vbox.offset_left = 10
	vbox.offset_top = 30
	vbox.offset_right = -10
	vbox.offset_bottom = -10
	
	var label = Label.new()
	label.text = message
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.add_theme_font_size_override("font_size", 20)
	
	if is_success:
		label.add_theme_color_override("font_color", Color.YELLOW)
	else:
		label.add_theme_color_override("font_color", Color.RED)
	
	vbox.add_child(label)
	popup.add_child(vbox)
	
	add_child(popup)
	active_popup = popup
	popup.popup_centered()
	
	# Автоматическое закрытие через duration секунд
	await get_tree().create_timer(duration).timeout
	
	if active_popup == popup and popup and is_instance_valid(popup):
		popup.queue_free()
		active_popup = null
		
		if on_closed.is_valid():
			on_closed.call()
